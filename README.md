# cordova-plugin-wkwebview-sandbox-webserver
A local web server serving sandbox content for WKWebview, inspired by apache/cordova-plugins and https://www.jianshu.com/p/db6386fada10 (an article in Chinese)

When you use WKWebview in Cordova, via cordova-plugin-wkwebview-engine, you lose access to your sandbox folder (like file:///var/mobile/Containers/Data/Application/<your app id>/, usually used for downloaded files)

What this plugin does is simple: it creates a web server exposing the sandbox folder to http://localhost:49086. Now you get access to your data files.

## Usage

```bash
cordova plugin add https://github.com/bigeyex/cordova-plugin-wkwebview-sandbox-webserver.git
```

and you are all set!
