# clipboard

[![pub package](https://img.shields.io/badge/0.1.2+6-brightgreen)](https://github.com/samuelezedi/flutter_clipboard)


[GitHub](https://github.com/samuelezedi/flutter_clipboard)


## Basic Usage:

```dart
import 'package:clipboard/clipboard.dart';
```

### Copy to clipboard from your app

```dart
  FlutterClipboard.copy('hello flutter friends').then(( value ) => print('copied'));
```

### Paste from clipboard what's copied anywhere in the device

```dart
FlutterClipboard.paste().then((value) {
  // Do what ever you want with the value.
  setState(() {
    field.text = value;
    pasteValue = value;
  });
});
```


## Why I made this plugin

I have built quite a few apps that required being able to copy to clipboard until I wanted to build a URL shortener,
now I needed users to be able to paste from clipboard and I discover the plugin I was using could not perform that, I
search and found another plugin that could paste from clipboard but would only paste what was copied from within your app
. Now I wanted user to paste what was in the Phones Clipboard, I discovered a way and then built this to help developers.
### kindly follow on github
[github](https://github.com/samuelezedi)

## Kindly follow me on
[twitter](https://twitter.com/samuelezedi)
[medium](https://medium.com/@samuelezedi)
[instagram](https://instagram.com/samuelezedi)