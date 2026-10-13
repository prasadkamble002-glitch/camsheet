// TurnApp factory wrapper — offline WebView.
// Loads local file: file:///android_asset/app/index.html (copied from apps/<name>/index.html at build time).
// Supports: JavaScript, <input type=file> picker, Blob downloads via DownloadManager.
package com.turnapp.factory

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.URLUtil
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import java.io.ByteArrayOutputStream
import java.io.File

/** Renders PDF pages to PNG using the built-in PdfRenderer (no libraries, offline).
 *  Called from app pages as TurnAppNative.renderPdfPageBase64(pdfBase64, pageIndex, targetWidthPx)
 *  Returns PNG base64, or "ERROR:..." on failure. */
class PdfBridge(private val ctx: Context) {

    @JavascriptInterface
    fun pdfPageCountBase64(pdfBase64: String): String {
        return try {
            val tmp = File.createTempFile("turnapp", ".pdf", ctx.cacheDir)
            try {
                tmp.writeBytes(Base64.decode(pdfBase64, Base64.DEFAULT))
                ParcelFileDescriptor.open(tmp, ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                    PdfRenderer(fd).use { r -> "PAGES:" + r.pageCount }
                }
            } finally {
                tmp.delete()
            }
        } catch (e: Exception) {
            "ERROR:" + (e.message ?: "cannot read PDF")
        }
    }

    @JavascriptInterface
    fun renderPdfPageBase64(pdfBase64: String, pageIndex: Int, targetWidth: Int): String {
        return try {
            val tmp = File.createTempFile("turnapp", ".pdf", ctx.cacheDir)
            try {
                tmp.writeBytes(Base64.decode(pdfBase64, Base64.DEFAULT))
                ParcelFileDescriptor.open(tmp, ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                    PdfRenderer(fd).use { renderer ->
                        if (pageIndex < 0 || pageIndex >= renderer.pageCount) {
                            return "ERROR:PDF has " + renderer.pageCount + " page(s)"
                        }
                        renderer.openPage(pageIndex).use { page ->
                            val w = if (targetWidth > 0) targetWidth else 1600
                            val h = (w.toFloat() * page.height / page.width).toInt().coerceAtLeast(1)
                            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                            bmp.eraseColor(Color.WHITE)
                            page.render(bmp, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            val out = ByteArrayOutputStream()
                            bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
                            Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
                        }
                    }
                }
            } finally {
                tmp.delete()
            }
        } catch (e: Exception) {
            "ERROR:" + (e.message ?: "render failed")
        }
    }
}

class MainActivity : AppCompatActivity() {

    private lateinit var web: WebView
    private var fileCallback: ValueCallback<Array<Uri>>? = null

    private val pickFiles = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val uris = mutableListOf<Uri>()
        val data: Intent? = result.data
        if (result.resultCode == RESULT_OK && data != null) {
            val clip = data.clipData
            if (clip != null) {
                for (i in 0 until clip.itemCount) uris += clip.getItemAt(i).uri
            } else {
                data.data?.let { uris += it }
            }
        }
        fileCallback?.onReceiveValue(uris.toTypedArray())
        fileCallback = null
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        web = WebView(this)
        setContentView(web)
        web.addJavascriptInterface(PdfBridge(this), "TurnAppNative")

        val s: WebSettings = web.settings
        s.javaScriptEnabled = true
        s.domStorageEnabled = true
        s.allowFileAccess = true
        s.allowContentAccess = true
        s.loadWithOverviewMode = true
        s.useWideViewPort = true
        s.builtInZoomControls = true
        s.displayZoomControls = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            s.safeBrowsingEnabled = false // fully local content
        }

        web.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                // Stay inside the app for local pages; open http(s) externally.
                val url = request.url.toString()
                if (url.startsWith("file:///android_asset/")) return false
                try { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) } catch (_: Exception) {}
                return true
            }
        }

        web.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(
                view: WebView, callback: ValueCallback<Array<Uri>>,
                params: FileChooserParams
            ): Boolean {
                fileCallback?.onReceiveValue(null)
                fileCallback = callback
                return try {
                    pickFiles.launch(params.createIntent().apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                    })
                    true
                } catch (_: Exception) {
                    fileCallback = null
                    false
                }
            }
        }

        // Blob: URLs can't be handled by DownloadManager directly.
        // Our apps use object-URL <a download> clicks which WebView downloads
        // via this listener for http(s)/data; blob: is handled by JS anchor click.
        web.setDownloadListener { url, userAgent, contentDisposition, mimeType, _ ->
            try {
                val name = URLUtil.guessFileName(url, contentDisposition, mimeType)
                val req = DownloadManager.Request(Uri.parse(url)).apply {
                    setMimeType(mimeType)
                    addRequestHeader("Cookie", android.webkit.CookieManager.getInstance().getCookie(url) ?: "")
                    setTitle(name)
                    setDescription("Saving from TurnApp")
                    setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                    setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, name)
                }
                (getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager).enqueue(req)
                android.widget.Toast.makeText(this, "Saving $name to Downloads…", android.widget.Toast.LENGTH_LONG).show()
            } catch (e: Exception) {
                android.widget.Toast.makeText(this, "Download failed: ${e.message}", android.widget.Toast.LENGTH_LONG).show()
            }
        }

        if (savedInstanceState == null) {
            web.loadUrl("file:///android_asset/app/index.html")
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        web.saveState(outState)
    }

    override fun onRestoreInstanceState(savedInstanceState: Bundle) {
        super.onRestoreInstanceState(savedInstanceState)
        web.restoreState(savedInstanceState)
    }

    @Deprecated("back button")
    override fun onBackPressed() {
        if (this::web.isInitialized && web.canGoBack()) web.goBack()
        else super.onBackPressed()
    }
}
