# clipboard

# Polls

[![pub package](https://img.shields.io/badge/pub-0.1.1-brightgreen)](https://github.com/samuelezedi/flutter_clipboard)


[GitHub](https://github.com/samuelezedi/flutter_clipboard)


## Usage

Basic:

```dart
import 'package:clipboard/clipboard.dart';
```

###To Copy to clipboard from your app

```dart
  FlutterClipboard.copy('hello flutter friends').then(( value ) => print('copied'));
```

### To Paste from clipboard whats copied anywhere in your phone

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

I have build quite a few app that required being able to copy to clipboard until I wanted to build a URL shortener,
now I need people to be able to paste from clipboard and I discover the plugin I was using could not perform that, I
search and found another plugin that could paste from clipboard but would only paste what was copied from within you app
. Now I wanted user to paste what was in the Phones Clipboard, I discovered a way and then built this to help many other developers.
### kindly follow on github
[github](https://github.com/samuelezedi)

## Kindly follow me on
[twitter](https://twitter.com/samuelezedi)
[medium](https://medium.com/@samuelezedi)
[instagram](https://instagram.com/samuelezedi)