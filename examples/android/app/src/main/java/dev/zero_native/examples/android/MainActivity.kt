package dev.zero_native.examples.android

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.webkit.WebView
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

class MainActivity : Activity(), SurfaceHolder.Callback {
    private var nativeApp: Long = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        System.loadLibrary("zero_native_example")

        val surface = SurfaceView(this)
        surface.holder.addCallback(this)

        val header = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(245, 246, 248))
            setPadding(32, 28, 32, 24)
        }
        val title = TextView(this).apply {
            text = "Mobile Shell"
            textSize = 24f
            setTextColor(Color.rgb(24, 24, 27))
        }
        val subtitle = TextView(this).apply {
            text = "Native header with WebView workspace"
            textSize = 14f
            setTextColor(Color.rgb(95, 102, 114))
            setPadding(0, 6, 0, 0)
        }
        header.addView(title)
        header.addView(subtitle)

        val webView = WebView(this).apply {
            settings.javaScriptEnabled = false
            loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        }

        val content = FrameLayout(this)
        content.addView(surface, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        ))
        content.addView(webView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        ))

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
        }
        root.addView(header, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ))
        root.addView(content, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1f,
        ))
        setContentView(root)

        nativeApp = nativeCreate()
        nativeStart(nativeApp)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        nativeResize(nativeApp, width.toFloat(), height.toFloat(), resources.displayMetrics.density, holder.surface)
        nativeFrame(nativeApp)
    }

    override fun surfaceCreated(holder: SurfaceHolder) = Unit

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        nativeStop(nativeApp)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        nativeTouch(nativeApp, event.getPointerId(0).toLong(), event.actionMasked, event.x, event.y, event.pressure)
        nativeFrame(nativeApp)
        return true
    }

    override fun onDestroy() {
        if (nativeApp != 0L) {
            nativeStop(nativeApp)
            nativeDestroy(nativeApp)
            nativeApp = 0
        }
        super.onDestroy()
    }

    external fun nativeCreate(): Long
    external fun nativeDestroy(app: Long)
    external fun nativeStart(app: Long)
    external fun nativeStop(app: Long)
    external fun nativeResize(app: Long, width: Float, height: Float, scale: Float, surface: Any)
    external fun nativeTouch(app: Long, id: Long, phase: Int, x: Float, y: Float, pressure: Float)
    external fun nativeFrame(app: Long)

    companion object {
        private const val html = """
            <!doctype html>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <body style="margin:0;font-family:system-ui,sans-serif;background:#f7f8fa;color:#18181b">
              <main style="padding:28px 22px;display:grid;gap:16px">
                <h1 style="margin:0;font-size:30px">Workspace</h1>
                <p style="margin:0;color:#5f6672;line-height:1.5">This content is rendered by Android WebView while the header remains native Android UI.</p>
                <section style="display:grid;gap:10px">
                  <div style="padding:14px;border:1px solid #e1e5ea;border-radius:8px;background:white">Inbox review</div>
                  <div style="padding:14px;border:1px solid #e1e5ea;border-radius:8px;background:white">Sync queue</div>
                  <div style="padding:14px;border:1px solid #e1e5ea;border-radius:8px;background:white">Offline cache</div>
                </section>
              </main>
            </body>
        """
    }
}
