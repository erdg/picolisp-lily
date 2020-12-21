## a simple melody app
a proof-of-concept app. Renders a simple melody to SVG (via LilyPond), and
displays it in the browser. Key, clef and time signature can changed and the
melody will dynamically update. Notes can be added, but not removed or edited.
There is no "undo".

### usage
Install JS deps and start the JS dev server
```
$ cd melody-app
$ npm install
$ npm start
```
In another terminal, install PL deps and start the PL server
```
$ cd melody-app
$ mkdir lib/
$ cd lib/
$ git clone https://github.com/aw/picolisp-json
$ git clone https://github.com/erdg/picolisp-minimal-http
$ cd ..
$ pil server.l -main -go +
```
Finally, point your browser to http://localhost:8080 (or whatever port the js
dev server tells you).
