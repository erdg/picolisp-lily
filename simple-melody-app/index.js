import './node_modules/ungrid/ungrid.min.css';
import { Component } from 'preact';

export default class App extends Component {
   state = {
      melody: '', // svg of music

      note: '',   // relative note
      timS: '',   // time signature
      keyS: '',   // key signature
      clef: '',

      dur: '',    // duration of music symbol, e.g. "4."
      pitch: '',  // pitch of music symbol, e.g. "aes"
      mus: '',    // current music symbol, e.g. "aes4."

   }

   onChange = (e) => {
      console.log('changed');
      this.setState({ [e.target.name]: e.target.value });
   }

   componentDidMount () {
      this.fetchMelody();
   }

   fetchMelody = () => {
      fetch('http://localhost:8888/!fetchMelody')
         .then(res => res.json())
         .then(json => {
            this.setState({ melody: json.melody })
         });
   }

   postMelody = () => {
      fetch('http://localhost:8888/!postMelody',
         {
            method: 'POST',
            body: JSON.stringify({
               note: this.state.note,
               timS: this.state.timS,
               keyS: this.state.keyS,
               clef: this.state.clef,
               mus:  this.state.mus
            })
         }
      )
      .then(res => res.json())
      .then(json => {
         this.setState({ melody: json.melody });
      });
   }
            
   render() {
      return (
         <div>
            <MelodyForm
               onChange={this.onChange}
               postMelody={this.postMelody}

               note={this.state.note}
               timS={this.state.timS}
               keyS={this.state.keyS}
               clef={this.state.clef}

               mus={this.state.mus}

            />
            <Melody melody={this.state.melody} />
         </div>
      );
   }
}

class Melody extends Component {
   render () {
      return (
         <span dangerouslySetInnerHTML={{__html: this.props.melody}} />
      );
   }
}

const MelodyForm = (props) => (
   <div class="col" style="width:20%">
      <label class="row">
         Relative Note
         <input type="text" name="note" value={props.note} onChange={props.onChange} />
      </label>
      <label class="row">
         Time Signature
         <input type="text" name="timS" value={props.timS} onChange={props.onChange} />
      </label>
      <label class="row">
         Key Signature
         <input type="text" name="keyS" value={props.keyS} onChange={props.onChange} />
      </label>
      <label class="row">
         Clef
         <input type="text" name="clef" value={props.clef} onChange={props.onChange} />
      </label>
      <br />
      <label class="row">
         Music Object
         <input type="text" name="mus" value={props.mus} onChange={props.onChange} />
      </label>
      <button onClick={props.postMelody}>
         Update Melody
      </button>
   </div>
)
