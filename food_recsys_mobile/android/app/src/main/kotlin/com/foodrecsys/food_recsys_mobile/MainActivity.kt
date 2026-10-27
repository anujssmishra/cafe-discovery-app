package com.foodrecsys.food_recsys_mobile

import android.app.Activity
import android.content.Intent
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets

class MainActivity : FlutterActivity() {
    private var pendingFile: MethodChannel.Result? = null
    private val fileRequest = 4207
    private val maxFileBytes = 5 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "food_recsys/order_files")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickOrderFile") {
                    result.notImplemented()
                } else if (pendingFile != null) {
                    result.error("PICKER_BUSY", "A file picker is already open.", null)
                } else {
                    pendingFile = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                            "text/*", "application/json", "application/csv",
                            "application/vnd.ms-excel", "application/octet-stream"
                        ))
                    }
                    try {
                        startActivityForResult(intent, fileRequest)
                    } catch (_: Exception) {
                        pendingFile = null
                        result.error("PICKER_UNAVAILABLE", "The file picker could not be opened.", null)
                    }
                }
            }
    }

    @Deprecated("Used for the Storage Access Framework result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != fileRequest) return
        val result = pendingFile ?: return
        pendingFile = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        Thread {
            try {
                var name = "order-history.txt"
                contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) name = cursor.getString(0) ?: name
                }
                val extension = name.substringAfterLast('.', "").lowercase()
                require(extension in setOf("csv", "json", "txt")) {
                    "Choose a CSV, JSON or TXT file. For a PDF receipt, paste its text instead."
                }
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val count = input.read(buffer)
                        if (count == -1) break
                        require(output.size() + count <= maxFileBytes) { "Files must be 5 MB or smaller." }
                        output.write(buffer, 0, count)
                    }
                    output.toByteArray()
                } ?: throw IllegalArgumentException("The selected file could not be read.")
                val text = StandardCharsets.UTF_8.newDecoder().decode(ByteBuffer.wrap(bytes)).toString()
                require(!text.contains('\u0000')) { "Choose a UTF-8 text file." }
                runOnUiThread { if (!isDestroyed) result.success(mapOf("name" to name, "text" to text)) }
            } catch (error: IllegalArgumentException) {
                runOnUiThread { if (!isDestroyed) result.error("INVALID_FILE", error.message, null) }
            } catch (_: Exception) {
                runOnUiThread { if (!isDestroyed) result.error("FILE_UNREADABLE", "The file could not be read as UTF-8 text.", null) }
            }
        }.start()
    }
}
