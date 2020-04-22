# stitch
Proof of concept for a sheet music dev environment.  All music
snippets will be displayed on a webpage, updates pushed to the page via
'serverSentEvent/serverSend'. Snippets are "draggable" via 'interactjs'.

It's like having all your music snippets on a digital table so you can move
them around and organize however you see fit.

### Usage
```
$ pil main.l -main -go +
```
and point your browser to `localhost:8080`.

#### Requirements
- pil64 >= 18.5.23 (for 'serverSentEvent's)
- interactjs (download 'interact.min.js' to this directory)
