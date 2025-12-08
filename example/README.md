# Example App - Enhanced Clipboard Demo

This example app demonstrates all features of the Enhanced Flutter Clipboard package, including the new image copy/paste functionality.

## Features Demonstrated

### Basic Features
- ✅ Text copy/paste
- ✅ Rich text (HTML) copy/paste
- ✅ Multiple format copy
- ✅ Callback support
- ✅ Clipboard monitoring
- ✅ Utility methods (hasData, isEmpty, getContentType, etc.)
- ✅ Debug information

### New Image Features (v2.0.2)
- ✅ **Image Selection**: Pick images from gallery
- ✅ **Image Copy**: Copy images to clipboard
- ✅ **Image Paste**: Paste images from clipboard
- ✅ **Multiple Format Copy**: Copy text + HTML + image simultaneously
- ✅ **Rich Paste**: Paste all formats including images
- ✅ **Image Display**: View selected and pasted images
- ✅ **Image History**: Clipboard history shows image entries

## Setup

1. Install dependencies:
```bash
cd example
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Image Testing Workflow

1. **Select Image**: Tap "Pick Image" to select an image from your gallery
2. **Copy Image**: Tap "Copy Image" to copy the selected image to clipboard
3. **Paste Image**: Tap "Paste Image" to retrieve the image from clipboard
4. **Copy Multiple**: Use "Copy Multiple (Text + Image)" to copy text and image together
5. **Paste All**: Use "Paste All Formats" to get text, HTML, and image if available

## Platform Notes

### Android
- Requires `READ_EXTERNAL_STORAGE` permission for image picking (handled by image_picker)
- Image clipboard works via platform channels
- May need FileProvider setup for Android 7.0+ (see main package README)

### iOS
- Requires photo library access permission (handled by image_picker)
- Image clipboard works via platform channels
- Full native support

### Web
- Image picking works via file input
- Image clipboard has limited browser support

## UI Sections

1. **Clipboard Status**: Shows current status and monitoring controls
2. **Input Section**: Text, HTML, and image selection
3. **Copy Operations**: All copy methods including image
4. **Paste Operations**: All paste methods including image
5. **Pasted Content**: Displays text and images
6. **Clipboard History**: Shows recent clipboard changes
7. **Debug Information**: Technical details for debugging

## Testing Tips

- Copy an image, then paste it to verify it works
- Copy text + image together, then paste to see both
- Monitor clipboard changes to see image entries
- Check debug info to see if native monitoring is active
- Test on both Android and iOS for platform differences
