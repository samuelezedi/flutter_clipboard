#include "clipboard_plugin.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shlobj.h>
#include <memory>
#include <sstream>
#include <vector>
#include <algorithm>

// GDI+ requires min/max macros which are disabled by NOMINMAX
// Define them explicitly for GDI+ headers
#ifndef min
#define min(a, b) (((a) < (b)) ? (a) : (b))
#endif
#ifndef max
#define max(a, b) (((a) > (b)) ? (a) : (b))
#endif

// Suppress warnings from GDI+ headers (C4458: declaration hides class member)
#pragma warning(push)
#pragma warning(disable: 4458)
#include <gdiplus.h>
#pragma warning(pop)

#undef min
#undef max
using namespace Gdiplus;
#pragma comment(lib, "gdiplus.lib")

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_stream_handler_functions.h>

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

class ClipboardPluginImpl {
 public:
  static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar_ref) {
    auto registrar = std::make_unique<flutter::PluginRegistrarWindows>(registrar_ref);
    auto plugin = std::make_unique<ClipboardPluginImpl>();
    
    auto method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "net.cubiclab.clipboard/methods",
        &flutter::StandardMethodCodec::GetInstance());
    
    auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        registrar->messenger(), "net.cubiclab.clipboard/events",
        &flutter::StandardMethodCodec::GetInstance());

    method_channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    event_channel->SetStreamHandler(
        std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
            [plugin_pointer = plugin.get()](const EncodableValue* arguments,
                                             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
                -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
              plugin_pointer->event_sink_ = events.release();
              return nullptr;
            },
            [plugin_pointer = plugin.get()](const EncodableValue* arguments)
                -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
              plugin_pointer->event_sink_ = nullptr;
              return nullptr;
            }));

    // Keep plugin and registrar alive
    static std::vector<std::unique_ptr<ClipboardPluginImpl>> plugins;
    static std::vector<std::unique_ptr<flutter::PluginRegistrarWindows>> registrars;
    plugins.push_back(std::move(plugin));
    registrars.push_back(std::move(registrar));
  }

  ClipboardPluginImpl() {}

  virtual ~ClipboardPluginImpl() {}

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    const std::string& method = method_call.method_name();
    const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());

    if (method == "copy") {
      HandleCopy(arguments, std::move(result));
    } else if (method == "copyRichText") {
      HandleCopyRichText(arguments, std::move(result));
    } else if (method == "copyMultiple") {
      HandleCopyMultiple(arguments, std::move(result));
    } else if (method == "copyImage") {
      HandleCopyImage(arguments, std::move(result));
    } else if (method == "paste") {
      HandlePaste(std::move(result));
    } else if (method == "pasteRichText") {
      HandlePasteRichText(std::move(result));
    } else if (method == "pasteImage") {
      HandlePasteImage(std::move(result));
    } else if (method == "getContentType") {
      HandleGetContentType(std::move(result));
    } else if (method == "hasData") {
      HandleHasData(std::move(result));
    } else if (method == "clear") {
      HandleClear(std::move(result));
    } else if (method == "getDataSize") {
      HandleGetDataSize(std::move(result));
    } else if (method == "startMonitoring") {
      result->Success(EncodableValue(true));
    } else if (method == "stopMonitoring") {
      result->Success(EncodableValue(true));
    } else {
      result->NotImplemented();
    }
  }

  void HandleCopy(const EncodableMap* arguments,
                  std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments are required");
      return;
    }

    auto text_it = arguments->find(EncodableValue("text"));
    if (text_it == arguments->end()) {
      result->Error("EMPTY_TEXT", "Text cannot be empty");
      return;
    }

    const auto* text = std::get_if<std::string>(&text_it->second);
    if (!text || text->empty()) {
      result->Error("EMPTY_TEXT", "Text cannot be empty");
      return;
    }

    if (OpenClipboard(nullptr)) {
      EmptyClipboard();
      
      // Convert to wide string for Windows
      int size_needed = MultiByteToWideChar(CP_UTF8, 0, text->c_str(), -1, NULL, 0);
      std::vector<wchar_t> wstr(size_needed);
      MultiByteToWideChar(CP_UTF8, 0, text->c_str(), -1, &wstr[0], size_needed);
      
      HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, (wstr.size()) * sizeof(wchar_t));
      if (hMem) {
        wchar_t* pMem = (wchar_t*)GlobalLock(hMem);
        wcscpy_s(pMem, wstr.size(), &wstr[0]);
        GlobalUnlock(hMem);
        SetClipboardData(CF_UNICODETEXT, hMem);
      }
      CloseClipboard();
      result->Success(EncodableValue(true));
    } else {
      result->Error("COPY_ERROR", "Failed to open clipboard");
    }
  }

  void HandleCopyRichText(const EncodableMap* arguments,
                          std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments are required");
      return;
    }

    std::string text;
    std::string html;

    auto text_it = arguments->find(EncodableValue("text"));
    if (text_it != arguments->end()) {
      const auto* text_ptr = std::get_if<std::string>(&text_it->second);
      if (text_ptr) text = *text_ptr;
    }

    auto html_it = arguments->find(EncodableValue("html"));
    if (html_it != arguments->end()) {
      const auto* html_ptr = std::get_if<std::string>(&html_it->second);
      if (html_ptr) html = *html_ptr;
    }

    if (text.empty() && html.empty()) {
      result->Error("EMPTY_CONTENT", "Either text or html must be provided");
      return;
    }

    if (OpenClipboard(nullptr)) {
      EmptyClipboard();
      
      // Set text
      if (!text.empty()) {
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, NULL, 0);
        std::vector<wchar_t> wstr(size_needed);
        MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, &wstr[0], size_needed);
        
        HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, (wstr.size()) * sizeof(wchar_t));
        if (hMem) {
          wchar_t* pMem = (wchar_t*)GlobalLock(hMem);
          wcscpy_s(pMem, wstr.size(), &wstr[0]);
          GlobalUnlock(hMem);
          SetClipboardData(CF_UNICODETEXT, hMem);
        }
      }

      // Set HTML if available
      if (!html.empty()) {
        UINT cf_html = RegisterClipboardFormatA("HTML Format");
        if (cf_html != 0) {
          std::string html_format = "Version:0.9\r\nStartHTML:00000000\r\nEndHTML:00000000\r\nStartFragment:00000000\r\nEndFragment:00000000\r\n";
          html_format += "<html><body><!--StartFragment-->";
          html_format += html;
          html_format += "<!--EndFragment--></body></html>";
          
          HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, html_format.size() + 1);
          if (hMem) {
            char* pMem = (char*)GlobalLock(hMem);
            strcpy_s(pMem, html_format.size() + 1, html_format.c_str());
            GlobalUnlock(hMem);
            SetClipboardData(cf_html, hMem);
          }
        }
      }

      CloseClipboard();
      result->Success(EncodableValue(true));
    } else {
      result->Error("COPY_RICH_ERROR", "Failed to open clipboard");
    }
  }

  void HandleCopyMultiple(const EncodableMap* arguments,
                          std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments are required");
      return;
    }

    auto formats_it = arguments->find(EncodableValue("formats"));
    if (formats_it == arguments->end()) {
      result->Error("EMPTY_FORMATS", "At least one format must be provided");
      return;
    }

    const auto* formats = std::get_if<EncodableMap>(&formats_it->second);
    if (!formats || formats->empty()) {
      result->Error("EMPTY_FORMATS", "At least one format must be provided");
      return;
    }

    if (OpenClipboard(nullptr)) {
      EmptyClipboard();

      // Handle image first
      auto image_it = formats->find(EncodableValue("image/png"));
      if (image_it != formats->end()) {
        const auto* image_bytes = std::get_if<EncodableList>(&image_it->second);
        if (image_bytes && !image_bytes->empty()) {
          std::vector<uint8_t> bytes;
          for (const auto& byte_val : *image_bytes) {
            if (const auto* byte_int32 = std::get_if<int32_t>(&byte_val)) {
              bytes.push_back(static_cast<uint8_t>(*byte_int32));
            } else if (const auto* byte_int64 = std::get_if<int64_t>(&byte_val)) {
              bytes.push_back(static_cast<uint8_t>(*byte_int64));
            }
          }
          if (!bytes.empty()) {
            SetClipboardImage(bytes);
          }
        }
      }

      // Handle text
      auto text_it = formats->find(EncodableValue("text/plain"));
      if (text_it != formats->end()) {
        const auto* text = std::get_if<std::string>(&text_it->second);
        if (text && !text->empty()) {
          int size_needed = MultiByteToWideChar(CP_UTF8, 0, text->c_str(), -1, NULL, 0);
          std::vector<wchar_t> wstr(size_needed);
          MultiByteToWideChar(CP_UTF8, 0, text->c_str(), -1, &wstr[0], size_needed);
          
          HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, (wstr.size()) * sizeof(wchar_t));
          if (hMem) {
            wchar_t* pMem = (wchar_t*)GlobalLock(hMem);
            wcscpy_s(pMem, wstr.size(), &wstr[0]);
            GlobalUnlock(hMem);
            SetClipboardData(CF_UNICODETEXT, hMem);
          }
        }
      }

      // Handle HTML
      auto html_it = formats->find(EncodableValue("text/html"));
      if (html_it != formats->end()) {
        const auto* html = std::get_if<std::string>(&html_it->second);
        if (html && !html->empty()) {
          UINT cf_html = RegisterClipboardFormatA("HTML Format");
          if (cf_html != 0) {
            std::string html_format = "Version:0.9\r\nStartHTML:00000000\r\nEndHTML:00000000\r\nStartFragment:00000000\r\nEndFragment:00000000\r\n";
            html_format += "<html><body><!--StartFragment-->";
            html_format += *html;
            html_format += "<!--EndFragment--></body></html>";
            
            HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, html_format.size() + 1);
            if (hMem) {
              char* pMem = (char*)GlobalLock(hMem);
              strcpy_s(pMem, html_format.size() + 1, html_format.c_str());
              GlobalUnlock(hMem);
              SetClipboardData(cf_html, hMem);
            }
          }
        }
      }

      CloseClipboard();
      result->Success(EncodableValue(true));
    } else {
      result->Error("COPY_MULTIPLE_ERROR", "Failed to open clipboard");
    }
  }

  void HandleCopyImage(const EncodableMap* arguments,
                       std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments are required");
      return;
    }

    auto image_bytes_it = arguments->find(EncodableValue("imageBytes"));
    if (image_bytes_it == arguments->end()) {
      result->Error("EMPTY_IMAGE", "Image bytes cannot be empty");
      return;
    }

    const auto* image_bytes = std::get_if<EncodableList>(&image_bytes_it->second);
    if (!image_bytes || image_bytes->empty()) {
      result->Error("EMPTY_IMAGE", "Image bytes cannot be empty");
      return;
    }

    std::vector<uint8_t> bytes;
    for (const auto& byte_val : *image_bytes) {
      if (const auto* byte_int32 = std::get_if<int32_t>(&byte_val)) {
        bytes.push_back(static_cast<uint8_t>(*byte_int32));
      } else if (const auto* byte_int64 = std::get_if<int64_t>(&byte_val)) {
        bytes.push_back(static_cast<uint8_t>(*byte_int64));
      }
    }

    if (bytes.empty()) {
      result->Error("EMPTY_IMAGE", "Image bytes cannot be empty");
      return;
    }

    if (OpenClipboard(nullptr)) {
      EmptyClipboard();
      bool success = SetClipboardImage(bytes);
      CloseClipboard();
      
      if (success) {
        result->Success(EncodableValue(true));
      } else {
        result->Error("COPY_IMAGE_ERROR", "Failed to copy image to clipboard");
      }
    } else {
      result->Error("COPY_IMAGE_ERROR", "Failed to open clipboard");
    }
  }

  bool SetClipboardImage(const std::vector<uint8_t>& png_bytes) {
    if (png_bytes.empty()) {
      return false;
    }

    // Initialize GDI+
    GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, nullptr);

    // Create IStream from PNG bytes
    IStream* pStream = nullptr;
    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, png_bytes.size());
    if (!hMem) {
      GdiplusShutdown(gdiplusToken);
      return false;
    }

    void* pMem = GlobalLock(hMem);
    if (!pMem) {
      GlobalFree(hMem);
      GdiplusShutdown(gdiplusToken);
      return false;
    }

    memcpy(pMem, png_bytes.data(), png_bytes.size());
    GlobalUnlock(hMem);

    if (CreateStreamOnHGlobal(hMem, TRUE, &pStream) != S_OK) {
      GlobalFree(hMem);
      GdiplusShutdown(gdiplusToken);
      return false;
    }

    // Load image from stream
    Bitmap* pBitmap = Bitmap::FromStream(pStream);
    if (!pBitmap || pBitmap->GetLastStatus() != Ok) {
      pStream->Release();
      GdiplusShutdown(gdiplusToken);
      if (pBitmap) delete pBitmap;
      return false;
    }

    // Get bitmap dimensions
    int width = pBitmap->GetWidth();
    int height = pBitmap->GetHeight();

    // Create DIB compatible with clipboard
    BITMAPINFOHEADER bih = {0};
    bih.biSize = sizeof(BITMAPINFOHEADER);
    bih.biWidth = width;
    bih.biHeight = -height; // Negative for top-down DIB
    bih.biPlanes = 1;
    bih.biBitCount = 32;
    bih.biCompression = BI_RGB;

    int rowSize = ((width * 32 + 31) / 32) * 4; // DWORD-aligned
    DWORD imageSize = rowSize * height;

    // Allocate memory for DIB
    HGLOBAL hDib = GlobalAlloc(GMEM_MOVEABLE, sizeof(BITMAPINFOHEADER) + imageSize);
    if (!hDib) {
      delete pBitmap;
      pStream->Release();
      GdiplusShutdown(gdiplusToken);
      return false;
    }

    BYTE* pDib = (BYTE*)GlobalLock(hDib);
    if (!pDib) {
      GlobalFree(hDib);
      delete pBitmap;
      pStream->Release();
      GdiplusShutdown(gdiplusToken);
      return false;
    }

    // Copy BITMAPINFOHEADER
    memcpy(pDib, &bih, sizeof(BITMAPINFOHEADER));
    BYTE* pBits = pDib + sizeof(BITMAPINFOHEADER);

    // Lock bitmap bits and copy pixel data
    BitmapData bitmapData;
    Rect rect(0, 0, width, height);
    
    if (pBitmap->LockBits(&rect, ImageLockModeRead, PixelFormat32bppARGB, &bitmapData) == Ok) {
      BYTE* pSource = (BYTE*)bitmapData.Scan0;
      
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // GDI+ uses BGRA format, DIB needs BGRA too, but we need to handle alpha
          BYTE b = pSource[y * bitmapData.Stride + x * 4 + 0];
          BYTE g = pSource[y * bitmapData.Stride + x * 4 + 1];
          BYTE r = pSource[y * bitmapData.Stride + x * 4 + 2];
          BYTE a = pSource[y * bitmapData.Stride + x * 4 + 3];
          
          // Copy to DIB (BGRA format)
          pBits[y * rowSize + x * 4 + 0] = b;
          pBits[y * rowSize + x * 4 + 1] = g;
          pBits[y * rowSize + x * 4 + 2] = r;
          pBits[y * rowSize + x * 4 + 3] = a;
        }
      }
      
      pBitmap->UnlockBits(&bitmapData);
    } else {
      GlobalUnlock(hDib);
      GlobalFree(hDib);
      delete pBitmap;
      pStream->Release();
      GdiplusShutdown(gdiplusToken);
      return false;
    }

    GlobalUnlock(hDib);

    // Set clipboard data
    bool success = (SetClipboardData(CF_DIB, hDib) != NULL);

    // Cleanup
    delete pBitmap;
    pStream->Release();
    GdiplusShutdown(gdiplusToken);

    return success;
  }

  void HandlePaste(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (OpenClipboard(nullptr)) {
      if (IsClipboardFormatAvailable(CF_UNICODETEXT)) {
        HGLOBAL hMem = GetClipboardData(CF_UNICODETEXT);
        if (hMem) {
          wchar_t* pMem = (wchar_t*)GlobalLock(hMem);
          int size_needed = WideCharToMultiByte(CP_UTF8, 0, pMem, -1, NULL, 0, NULL, NULL);
          std::vector<char> str(size_needed);
          WideCharToMultiByte(CP_UTF8, 0, pMem, -1, &str[0], size_needed, NULL, NULL);
          GlobalUnlock(hMem);
          
          EncodableMap result_map;
          result_map[EncodableValue("text")] = EncodableValue(std::string(&str[0]));
          result->Success(EncodableValue(result_map));
        } else {
          result->Success(EncodableValue(EncodableMap{{EncodableValue("text"), EncodableValue("")}}));
        }
      } else {
        result->Success(EncodableValue(EncodableMap{{EncodableValue("text"), EncodableValue("")}}));
      }
      CloseClipboard();
    } else {
      result->Error("PASTE_ERROR", "Failed to open clipboard");
    }
  }

  void HandlePasteRichText(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    EncodableMap result_map;
    
    if (OpenClipboard(nullptr)) {
      // Get text
      std::string text;
      if (IsClipboardFormatAvailable(CF_UNICODETEXT)) {
        HGLOBAL hMem = GetClipboardData(CF_UNICODETEXT);
        if (hMem) {
          wchar_t* pMem = (wchar_t*)GlobalLock(hMem);
          int size_needed = WideCharToMultiByte(CP_UTF8, 0, pMem, -1, NULL, 0, NULL, NULL);
          std::vector<char> str(size_needed);
          WideCharToMultiByte(CP_UTF8, 0, pMem, -1, &str[0], size_needed, NULL, NULL);
          GlobalUnlock(hMem);
          text = std::string(&str[0]);
        }
      }
      result_map[EncodableValue("text")] = EncodableValue(text);

      // Get HTML
      UINT cf_html = RegisterClipboardFormatA("HTML Format");
      std::string html;
      if (cf_html != 0 && IsClipboardFormatAvailable(cf_html)) {
        HGLOBAL hMem = GetClipboardData(cf_html);
        if (hMem) {
          char* pMem = (char*)GlobalLock(hMem);
          html = std::string(pMem);
          GlobalUnlock(hMem);
        }
      }
      result_map[EncodableValue("html")] = EncodableValue(html);

      result_map[EncodableValue("timestamp")] = EncodableValue(static_cast<int64_t>(GetTickCount64()));
      
      CloseClipboard();
      result->Success(EncodableValue(result_map));
    } else {
      result->Error("PASTE_RICH_ERROR", "Failed to open clipboard");
    }
  }

  void HandlePasteImage(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    EncodableMap result_map;
    
    if (!OpenClipboard(nullptr)) {
      result->Error("PASTE_IMAGE_ERROR", "Failed to open clipboard");
      return;
    }

    if (!IsClipboardFormatAvailable(CF_DIB)) {
      CloseClipboard();
      result->Success(EncodableValue(result_map));
      return;
    }

    HGLOBAL hMem = GetClipboardData(CF_DIB);
    if (!hMem) {
      CloseClipboard();
      result->Success(EncodableValue(result_map));
      return;
    }

    // Initialize GDI+
    GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, nullptr);

    // Lock the clipboard memory
    BITMAPINFOHEADER* pBih = (BITMAPINFOHEADER*)GlobalLock(hMem);
    if (!pBih) {
      GlobalUnlock(hMem);
      CloseClipboard();
      GdiplusShutdown(gdiplusToken);
      result->Success(EncodableValue(result_map));
      return;
    }

    // Get bitmap dimensions
    int width = pBih->biWidth;
    int height = abs(pBih->biHeight);
    bool isTopDown = (pBih->biHeight < 0);
    int bitsPerPixel = pBih->biBitCount;

    // Calculate row size for DIB
    int rowSize = ((width * bitsPerPixel + 31) / 32) * 4;
    
    // DIB may have color table for formats < 24 bits
    // For 24 and 32 bit, pixels start right after header
    BYTE* pBits = (BYTE*)(pBih + 1);
    if (bitsPerPixel <= 8) {
      // Skip color table (2^bitsPerPixel entries, each 4 bytes)
      int colorTableSize = static_cast<int>((1ULL << bitsPerPixel) * sizeof(RGBQUAD));
      pBits = (BYTE*)pBih + sizeof(BITMAPINFOHEADER) + colorTableSize;
    }

    // Create GDI+ Bitmap from DIB
    Bitmap* pBitmap = new Bitmap(width, height, PixelFormat32bppARGB);
    if (!pBitmap || pBitmap->GetLastStatus() != Ok) {
      GlobalUnlock(hMem);
      CloseClipboard();
      GdiplusShutdown(gdiplusToken);
      if (pBitmap) delete pBitmap;
      result->Success(EncodableValue(result_map));
      return;
    }

    // Copy pixel data to bitmap
    BitmapData bitmapData;
    Rect rect(0, 0, width, height);

    if (pBitmap->LockBits(&rect, ImageLockModeWrite, PixelFormat32bppARGB, &bitmapData) == Ok) {
      BYTE* pDest = (BYTE*)bitmapData.Scan0;
      BYTE* pSource = isTopDown ? pBits : (pBits + (rowSize * (height - 1)));
      int sourceStep = isTopDown ? rowSize : -rowSize;

      for (int y = 0; y < height; y++) {
        BYTE* pDestRow = pDest + y * bitmapData.Stride;
        if (bitsPerPixel == 32) {
          // DIB stores BGRA, GDI+ PixelFormat32bppARGB also uses BGRA in memory
          // Copy directly row by row
          memcpy(pDestRow, pSource, width * 4);
        } else if (bitsPerPixel == 24) {
          // Convert 24-bit BGR to 32-bit BGRA
          for (int x = 0; x < width; x++) {
            pDestRow[x * 4 + 0] = pSource[x * 3 + 0]; // B = B
            pDestRow[x * 4 + 1] = pSource[x * 3 + 1]; // G = G
            pDestRow[x * 4 + 2] = pSource[x * 3 + 2]; // R = R
            pDestRow[x * 4 + 3] = 255; // Alpha
          }
        } else {
          // For other formats, we'd need more complex conversion
          pBitmap->UnlockBits(&bitmapData);
          GlobalUnlock(hMem);
          CloseClipboard();
          delete pBitmap;
          GdiplusShutdown(gdiplusToken);
          result->Success(EncodableValue(result_map));
          return;
        }
        pSource += sourceStep;
      }

      pBitmap->UnlockBits(&bitmapData);
    }

    // Unlock clipboard memory and close clipboard
    GlobalUnlock(hMem);
    CloseClipboard();

    // Convert bitmap to PNG bytes
    IStream* pStream = nullptr;
    if (CreateStreamOnHGlobal(nullptr, TRUE, &pStream) != S_OK) {
      delete pBitmap;
      GdiplusShutdown(gdiplusToken);
      result->Success(EncodableValue(result_map));
      return;
    }

    // Save as PNG
    CLSID clsidPng;
    if (CLSIDFromString(L"{557CF406-1A04-11D3-9A73-0000F81EF32E}", &clsidPng) == S_OK) {
      if (pBitmap->Save(pStream, &clsidPng, nullptr) == Ok) {
        // Get stream size
        STATSTG stat;
        if (pStream->Stat(&stat, STATFLAG_NONAME) == S_OK) {
          ULARGE_INTEGER pos;
          LARGE_INTEGER zero = {0};
          pStream->Seek(zero, STREAM_SEEK_SET, &pos);

          // Read PNG bytes
          ULONG bytesRead = 0;
          std::vector<uint8_t> pngBytes(stat.cbSize.LowPart);
          pStream->Read(pngBytes.data(), stat.cbSize.LowPart, &bytesRead);

          // Convert to EncodableList for Flutter
          EncodableList imageBytes;
          imageBytes.reserve(bytesRead);
          for (ULONG i = 0; i < bytesRead; i++) {
            imageBytes.push_back(EncodableValue(static_cast<int32_t>(pngBytes[i])));
          }
          result_map[EncodableValue("imageBytes")] = EncodableValue(imageBytes);
        }
      }
    }

    pStream->Release();
    delete pBitmap;
    GdiplusShutdown(gdiplusToken);

    result->Success(EncodableValue(result_map));
  }

  void HandleGetContentType(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (OpenClipboard(nullptr)) {
      bool has_text = IsClipboardFormatAvailable(CF_UNICODETEXT);
      UINT cf_html = RegisterClipboardFormatA("HTML Format");
      bool has_html = (cf_html != 0 && IsClipboardFormatAvailable(cf_html));
      bool has_image = IsClipboardFormatAvailable(CF_DIB);
      
      std::string content_type = "empty";
      if (has_image && (has_text || has_html)) {
        content_type = "mixed";
      } else if (has_image) {
        content_type = "image";
      } else if (has_text && has_html) {
        content_type = "mixed";
      } else if (has_html) {
        content_type = "html";
      } else if (has_text) {
        content_type = "text";
      }
      
      CloseClipboard();
      result->Success(EncodableValue(content_type));
    } else {
      result->Success(EncodableValue("unknown"));
    }
  }

  void HandleHasData(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (OpenClipboard(nullptr)) {
      bool has_data = IsClipboardFormatAvailable(CF_UNICODETEXT) ||
                      IsClipboardFormatAvailable(CF_DIB) ||
                      (RegisterClipboardFormatA("HTML Format") != 0 && 
                       IsClipboardFormatAvailable(RegisterClipboardFormatA("HTML Format")));
      CloseClipboard();
      result->Success(EncodableValue(has_data));
    } else {
      result->Success(EncodableValue(false));
    }
  }

  void HandleClear(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (OpenClipboard(nullptr)) {
      EmptyClipboard();
      CloseClipboard();
      result->Success(EncodableValue(true));
    } else {
      result->Error("CLEAR_ERROR", "Failed to open clipboard");
    }
  }

  void HandleGetDataSize(std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    if (OpenClipboard(nullptr)) {
      int size = 0;
      if (IsClipboardFormatAvailable(CF_UNICODETEXT)) {
        HGLOBAL hMem = GetClipboardData(CF_UNICODETEXT);
        if (hMem) {
          size = static_cast<int>(GlobalSize(hMem));
        }
      }
      CloseClipboard();
      result->Success(EncodableValue(size));
    } else {
      result->Success(EncodableValue(0));
    }
  }

  flutter::EventSink<flutter::EncodableValue>* event_sink_ = nullptr;
};

}  // namespace

void ClipboardPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ClipboardPluginImpl::RegisterWithRegistrar(registrar);
}

