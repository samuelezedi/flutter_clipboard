package net.cubiclab.clipboard

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.util.Base64
import android.content.ContentResolver
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class ClipboardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var clipboardManager: ClipboardManager? = null
    private var clipboardChangeListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        clipboardManager = context?.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager

        methodChannel = MethodChannel(binding.binaryMessenger, "net.cubiclab.clipboard/methods")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "net.cubiclab.clipboard/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopMonitoring()
        context = null
        clipboardManager = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "copy" -> {
                val text = call.argument<String>("text") ?: ""
                if (text.isEmpty()) {
                    result.error("EMPTY_TEXT", "Text cannot be empty", null)
                    return
                }
                try {
                    val clip = ClipData.newPlainText("text", text)
                    clipboardManager?.setPrimaryClip(clip)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("COPY_ERROR", e.message, null)
                }
            }
            "copyRichText" -> {
                val text = call.argument<String>("text") ?: ""
                val html = call.argument<String>("html")
                if (text.isEmpty() && (html == null || html.isEmpty())) {
                    result.error("EMPTY_CONTENT", "Either text or html must be provided", null)
                    return
                }
                try {
                    if (html != null && html.isNotEmpty()) {
                        val clip = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                            ClipData.newHtmlText("html", text, html)
                        } else {
                            ClipData.newPlainText("text", text)
                        }
                        clipboardManager?.setPrimaryClip(clip)
                    } else {
                        val clip = ClipData.newPlainText("text", text)
                        clipboardManager?.setPrimaryClip(clip)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("COPY_RICH_ERROR", e.message, null)
                }
            }
            "copyMultiple" -> {
                val formats = call.argument<Map<String, Any>>("formats") ?: emptyMap()
                if (formats.isEmpty()) {
                    result.error("EMPTY_FORMATS", "At least one format must be provided", null)
                    return
                }
                try {
                    val text = formats["text/plain"]?.toString() ?: ""
                    val html = formats["text/html"]?.toString()
                    val imageBytes = formats["image/png"] as? List<Int>

                    // Handle image first (highest priority)
                    if (imageBytes != null && imageBytes.isNotEmpty()) {
                        val byteArray = imageBytes.map { it.toByte() }.toByteArray()
                        val bitmap = bytesToBitmap(byteArray)
                        if (bitmap != null) {
                            val imageUri = saveBitmapToCache(bitmap)
                            if (imageUri != null) {
                                val clip = ClipData.newUri(context?.contentResolver, "image", imageUri)
                                if (text.isNotEmpty()) {
                                    clip.addItem(ClipData.Item(text))
                                }
                                clipboardManager?.setPrimaryClip(clip)
                                result.success(true)
                                return
                            }
                        }
                    }

                    // Fallback to HTML or text
                    if (html != null && html.isNotEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                        val clip = ClipData.newHtmlText("html", text, html)
                        clipboardManager?.setPrimaryClip(clip)
                    } else if (text.isNotEmpty()) {
                        val clip = ClipData.newPlainText("text", text)
                        clipboardManager?.setPrimaryClip(clip)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("COPY_MULTIPLE_ERROR", e.message, null)
                }
            }
            "copyImage" -> {
                val imageBytes = call.argument<List<Int>>("imageBytes")
                if (imageBytes == null || imageBytes.isEmpty()) {
                    result.error("EMPTY_IMAGE", "Image bytes cannot be empty", null)
                    return
                }
                try {
                    val byteArray = imageBytes.map { it.toByte() }.toByteArray()
                    val bitmap = bytesToBitmap(byteArray)
                    if (bitmap == null) {
                        result.error("INVALID_IMAGE", "Failed to decode image", null)
                        return
                    }
                    val imageUri = saveBitmapToCache(bitmap)
                    if (imageUri == null) {
                        result.error("SAVE_ERROR", "Failed to save image to cache", null)
                        return
                    }
                    val clip = ClipData.newUri(context?.contentResolver, "image", imageUri)
                    clipboardManager?.setPrimaryClip(clip)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("COPY_IMAGE_ERROR", e.message, null)
                }
            }
            "paste" -> {
                try {
                    val clipData = clipboardManager?.primaryClip
                    val text = clipData?.getItemAt(0)?.text?.toString() ?: ""
                    result.success(mapOf("text" to text))
                } catch (e: Exception) {
                    result.error("PASTE_ERROR", e.message, null)
                }
            }
            "pasteRichText" -> {
                try {
                    val clipData = clipboardManager?.primaryClip
                    val item = clipData?.getItemAt(0)
                    val text = item?.text?.toString() ?: ""
                    val html = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                        item?.htmlText
                    } else {
                        null
                    }
                    
                    // Try to get image from clipboard
                    val imageBytes = getImageFromClipboard(item)
                    
                    val resultMap = mutableMapOf<String, Any?>(
                        "text" to text,
                        "html" to html,
                        "imageBytes" to imageBytes,
                        "timestamp" to System.currentTimeMillis()
                    )
                    result.success(resultMap)
                } catch (e: Exception) {
                    result.error("PASTE_RICH_ERROR", e.message, null)
                }
            }
            "pasteImage" -> {
                try {
                    val clipData = clipboardManager?.primaryClip
                    val item = clipData?.getItemAt(0)
                    val imageBytes = getImageFromClipboard(item)
                    if (imageBytes != null) {
                        result.success(mapOf("imageBytes" to imageBytes))
                    } else {
                        result.success(mapOf("imageBytes" to null))
                    }
                } catch (e: Exception) {
                    result.error("PASTE_IMAGE_ERROR", e.message, null)
                }
            }
            "getContentType" -> {
                try {
                    val clipData = clipboardManager?.primaryClip
                    if (clipData == null || clipData.itemCount == 0) {
                        result.success("empty")
                        return
                    }
                    val item = clipData.getItemAt(0)
                    val hasText = item?.text != null
                    val hasHtml = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                        item?.htmlText != null
                    } else {
                        false
                    }
                    val hasImage = item?.uri != null && isImageUri(item.uri)
                    
                    when {
                        hasImage && (hasText || hasHtml) -> result.success("mixed")
                        hasImage -> result.success("image")
                        hasText && hasHtml -> result.success("mixed")
                        hasHtml -> result.success("html")
                        hasText -> result.success("text")
                        else -> result.success("empty")
                    }
                } catch (e: Exception) {
                    result.success("unknown")
                }
            }
            "hasData" -> {
                try {
                    val clipData = clipboardManager?.primaryClip
                    val hasData = clipData != null && clipData.itemCount > 0
                    result.success(hasData)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            "clear" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        clipboardManager?.clearPrimaryClip()
                    } else {
                        val clip = ClipData.newPlainText("", "")
                        clipboardManager?.setPrimaryClip(clip)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("CLEAR_ERROR", e.message, null)
                }
            }
            "getDataSize" -> {
                try {
                    val clipData = clipboardManager?.primaryClip
                    val text = clipData?.getItemAt(0)?.text?.toString() ?: ""
                    result.success(text.length)
                } catch (e: Exception) {
                    result.success(0)
                }
            }
            "startMonitoring" -> {
                startMonitoring()
                result.success(true)
            }
            "stopMonitoring" -> {
                stopMonitoring()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startMonitoring() {
        if (clipboardChangeListener != null) {
            return
        }
        clipboardChangeListener = ClipboardManager.OnPrimaryClipChangedListener {
            try {
                val clipData = clipboardManager?.primaryClip
                val item = clipData?.getItemAt(0)
                val text = item?.text?.toString() ?: ""
                val html = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                    item?.htmlText
                } else {
                    null
                }
                val eventMap = mapOf(
                    "text" to text,
                    "html" to html,
                    "timestamp" to System.currentTimeMillis()
                )
                eventSink?.success(eventMap)
            } catch (e: Exception) {
                // Ignore errors
            }
        }
        clipboardManager?.addPrimaryClipChangedListener(clipboardChangeListener!!)
    }

    private fun stopMonitoring() {
        clipboardChangeListener?.let {
            clipboardManager?.removePrimaryClipChangedListener(it)
            clipboardChangeListener = null
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startMonitoring()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopMonitoring()
    }

    private fun bytesToBitmap(bytes: ByteArray): Bitmap? {
        return try {
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        } catch (e: Exception) {
            null
        }
    }

    private fun saveBitmapToCache(bitmap: Bitmap): Uri? {
        return try {
            val context = this.context ?: return null
            val cacheDir = context.cacheDir
            val imageFile = File(cacheDir, "clipboard_image_${System.currentTimeMillis()}.png")
            
            FileOutputStream(imageFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                android.content.FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    imageFile
                )
            } else {
                Uri.fromFile(imageFile)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getImageFromClipboard(item: ClipData.Item?): List<Int>? {
        return try {
            val uri = item?.uri ?: return null
            if (!isImageUri(uri)) return null
            
            val context = this.context ?: return null
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            
            val bitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()
            
            if (bitmap == null) return null
            
            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            val byteArray = outputStream.toByteArray()
            outputStream.close()
            
            byteArray.toList()
        } catch (e: Exception) {
            null
        }
    }

    private fun isImageUri(uri: Uri): Boolean {
        val mimeType = context?.contentResolver?.getType(uri)
        return mimeType?.startsWith("image/") == true
    }
}

