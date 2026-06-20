package com.yonderchat.not_interested

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import java.nio.FloatBuffer

class NudeNetDetector(private val context: Context) {

    private val env = OrtEnvironment.getEnvironment()
    private var session: OrtSession? = null

    companion object {
        private const val MODEL_PATH = "flutter_assets/models/nudenet_320n.onnx"
        private const val INPUT_SIZE = 320
        private const val CONF_MIN = 0.2f
        private const val NMS_IOU_THRESHOLD = 0.45f

        // Class index → label (18 classes, indices 0–17)
        private val LABELS = arrayOf(
            "FEMALE_GENITALIA_COVERED", "FACE_FEMALE", "BUTTOCKS_EXPOSED",
            "FEMALE_BREAST_EXPOSED", "FEMALE_GENITALIA_EXPOSED", "MALE_BREAST_EXPOSED",
            "ANUS_EXPOSED", "FEET_EXPOSED", "BELLY_COVERED", "FEET_COVERED",
            "ARMPITS_COVERED", "ARMPITS_EXPOSED", "FACE_MALE", "BELLY_EXPOSED",
            "MALE_GENITALIA_EXPOSED", "ANUS_COVERED", "FEMALE_BREAST_COVERED", "BUTTOCKS_COVERED"
        )

        // Only blur genuinely exposed sensitive parts
        private val BLUR_CLASSES = setOf(2, 3, 4, 6, 14)
        // 2=BUTTOCKS_EXPOSED, 3=FEMALE_BREAST_EXPOSED, 4=FEMALE_GENITALIA_EXPOSED,
        // 6=ANUS_EXPOSED, 14=MALE_GENITALIA_EXPOSED
    }

    fun load() {
        val bytes = context.assets.open(MODEL_PATH).readBytes()
        session = env.createSession(bytes, OrtSession.SessionOptions())
    }

    fun detect(bitmap: Bitmap, confidenceThreshold: Float): List<RectF> {
        val sess = session ?: return emptyList()

        val origW = bitmap.width.toFloat()
        val origH = bitmap.height.toFloat()
        val maxSide = maxOf(origW, origH)

        // Letterbox: pad to square, then resize to 320×320
        val squared = letterbox(bitmap, maxSide.toInt())
        val input = toNchwTensor(squared)
        squared.recycle()

        val shape = longArrayOf(1, 3, INPUT_SIZE.toLong(), INPUT_SIZE.toLong())
        val tensor = OnnxTensor.createTensor(env, input, shape)
        val result = sess.run(mapOf("images" to tensor))

        // output0: shape [1, 22, 2100] → flat buffer, row-major
        val outputTensor = result.get("output0").get() as OnnxTensor
        val buf = outputTensor.floatBuffer  // size = 22 * 2100
        val numBoxes = 2100
        val numFeatures = 22  // 4 coords + 18 classes

        val boxes = mutableListOf<FloatArray>()

        for (b in 0 until numBoxes) {
            val xc = buf[0 * numBoxes + b]
            val yc = buf[1 * numBoxes + b]
            val w  = buf[2 * numBoxes + b]
            val h  = buf[3 * numBoxes + b]

            var maxScore = 0f
            var bestClass = -1
            for (c in 0 until 18) {
                val score = buf[(4 + c) * numBoxes + b]
                if (score > maxScore) { maxScore = score; bestClass = c }
            }

            if (maxScore < CONF_MIN || bestClass !in BLUR_CLASSES) continue
            if (maxScore < confidenceThreshold) continue

            // Convert from 320-space to normalized original coords
            // The padded image is maxSide×maxSide scaled to 320×320
            val scale = maxSide / INPUT_SIZE
            val x1 = ((xc - w / 2f) * scale).coerceIn(0f, origW) / origW
            val y1 = ((yc - h / 2f) * scale).coerceIn(0f, origH) / origH
            val x2 = ((xc + w / 2f) * scale).coerceIn(0f, origW) / origW
            val y2 = ((yc + h / 2f) * scale).coerceIn(0f, origH) / origH

            if (x2 > x1 && y2 > y1) {
                boxes.add(floatArrayOf(x1, y1, x2, y2, maxScore))
            }
        }

        result.close()
        tensor.close()

        return nms(boxes).map { RectF(it[0], it[1], it[2], it[3]) }
    }

    private fun letterbox(src: Bitmap, maxSide: Int): Bitmap {
        val padded = Bitmap.createBitmap(maxSide, maxSide, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(padded)
        canvas.drawColor(Color.BLACK)
        canvas.drawBitmap(src, 0f, 0f, null)
        val scaled = Bitmap.createScaledBitmap(padded, INPUT_SIZE, INPUT_SIZE, true)
        padded.recycle()
        return scaled
    }

    private fun toNchwTensor(bitmap: Bitmap): FloatBuffer {
        val pixels = IntArray(INPUT_SIZE * INPUT_SIZE)
        bitmap.getPixels(pixels, 0, INPUT_SIZE, 0, 0, INPUT_SIZE, INPUT_SIZE)

        val buffer = FloatBuffer.allocate(3 * INPUT_SIZE * INPUT_SIZE)
        val rOffset = 0
        val gOffset = INPUT_SIZE * INPUT_SIZE
        val bOffset = INPUT_SIZE * INPUT_SIZE * 2

        for (i in pixels.indices) {
            val p = pixels[i]
            buffer.put(rOffset + i, Color.red(p) / 255f)
            buffer.put(gOffset + i, Color.green(p) / 255f)
            buffer.put(bOffset + i, Color.blue(p) / 255f)
        }

        return buffer
    }

    private fun nms(boxes: List<FloatArray>): List<FloatArray> {
        val sorted = boxes.sortedByDescending { it[4] }
        val suppressed = BooleanArray(sorted.size)
        val kept = mutableListOf<FloatArray>()

        for (i in sorted.indices) {
            if (suppressed[i]) continue
            kept.add(sorted[i])
            for (j in i + 1 until sorted.size) {
                if (!suppressed[j] && iou(sorted[i], sorted[j]) > NMS_IOU_THRESHOLD) {
                    suppressed[j] = true
                }
            }
        }
        return kept
    }

    private fun iou(a: FloatArray, b: FloatArray): Float {
        val x1 = maxOf(a[0], b[0])
        val y1 = maxOf(a[1], b[1])
        val x2 = minOf(a[2], b[2])
        val y2 = minOf(a[3], b[3])
        val inter = maxOf(0f, x2 - x1) * maxOf(0f, y2 - y1)
        val aArea = (a[2] - a[0]) * (a[3] - a[1])
        val bArea = (b[2] - b[0]) * (b[3] - b[1])
        val union = aArea + bArea - inter
        return if (union == 0f) 0f else inter / union
    }

    fun close() {
        session?.close()
        session = null
    }
}
