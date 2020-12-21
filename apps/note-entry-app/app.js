import { h, app } from "./hyperapp.js"

const state = {
   note: "e",
   duration: "2",
   octave: "",
   clef: "bass",
}

const actions = {
   setNote: note => state => {
      if (state.clef == "bass") {
         if ((note <= "b") && (state.octave == "")) {
            return { note: note, octave: "-" }
         }
         if ((note != "g") && (note >= "c") && (state.octave == "-")) {
            return { note: note, octave: "" }
         }
      }
      return {note: note}
   },
   setOctave: octave => state => ({ octave }),
   setClef: clef => state => ({ clef }),
   alertNote: note => alert(note),
   getState: () => state => state
}

const Img = (props) => (
   h("img",
      {
         src: props.src,
         style: {
            position: "absolute",
            top: 0,
            left: 0,
            zIndex: -1,
         }
      },
      [] 
   )
)

const Obj = (props) => (
   h("object",
      {
         data: props.data,
         type: props.type,
         setNote: (note) => props.setNote(note),
         style: {
            position: "absolute",
            top: 0,
            left: 0,
            zIndex: props.zIndex 
         }
      },
      []
   )
)

const view = (state, actions) =>
   h("div",
      {
         style: {
            position: "relative",
         }
      },
      [
         // Img({ src: `http://localhost:8000/svg/${state.clef}-clef/${state.clef}-clef.svg` }),
         Obj({ 
            data: `http://localhost:8000/svg/${state.clef}-clef/${state.clef}-clef.svg`,
            type: "image/svg+xml",
            setNote: (note) => {
               actions.setNote(note);
            },
            zIndex: -1,
         }),
         Obj({ 
            data: `http://localhost:8000/svg/${state.clef}-clef/${state.note}${state.octave}${state.duration}.svg`,
            type: "image/svg+xml",
            setNote: (note) => {
               actions.setNote(note);
            },
            zIndex: 10
         }),
      ]
   );

window.main = app(state, actions, view, document.body);
