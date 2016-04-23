/**
 * ##copyright##
 * See LICENSE.md
 *
 * @author    Maxime Damecour (http://nnvtn.ca)
 * @version   0.4
 * @since     2016-04-01
 */


/**
 * The FreelinerCommunicator handles communication with other programs over various protocols.
 */
class Documenter implements FreelinerConfig{
  ArrayList<ArrayList<Mode>> docBuffer;
  ArrayList<String> sections;
  PrintWriter output;

  /**
   * Constructor
   */
  public Documenter(){
    docBuffer = new ArrayList();
    sections = new ArrayList();
    sections.add("First");
    output = createWriter("doc/autodoc.md");
    output.flush();
    documentKeys();
  }

  /**
   * Creates markdown for keyboard shortcuts!
   */
  void documentKeys(){
    // print keyboard type, osx? azerty?
    output.println("### keys ###");
    output.println("| key | parameter |");
    output.println("|:---:|---|");
    for(String _s : KEY_MAP){
      String _ks = _s.replaceAll(" ", "");
      output.println("| `"+_ks.charAt(0)+"` | "+_ks.substring(1)+" |");
    }
    output.println(" ");
    output.println("### ctrl keys ###");
    output.println("| key | action |");
    output.println("|:---:|---|");
    for(String _s : CTRL_KEY_MAP){
      String _ks = _s.replaceAll(" ", "");
      output.println("| `ctrl+"+_ks.charAt(0)+"` | "+_ks.substring(1)+" |");
    }
    output.println(" ");
  }

  /**
   * Add a array of "modes", their associated key, and their section name.
   * @param Mode[] array of modes to be added to doc.
   * @param char key associated with mode slection (q for stroke color)
   * @param String section name (ColorModes)
   */
  void addDoc(Mode[] _modes, char _key, String _section){
    if(!hasSection(_section)){
      sections.add(_section);
      //ArrayList<Mode> _buff = new ArrayList();
      //for(Mode _m : _modes) _buff.add(_m);
      //docBuffer.add(_buff);
      addDocToFile(_modes,_key,_section);
    }
  }

  /**
   * As many things get instatiated we need to make sure we only add a section once
   * @param String sectionName
   */
  boolean hasSection(String _section){
    for(String _s : sections)
      if(_s.equals(_section)) return true;
    return false;
  }

  /**
   * Output markdown file
   */
  void outputMarkdown(){
    // output.flush();
    // for(ArrayList<Mode> _section : docBuffer){
    //   addDocToFile(_section);
    // }
    output.close();
    println("Saved doc to : doc/autodoc.md");
  }

  /**
   * Format mode arrays to nice markdown tables
   * @param String cmd
   */
  void addDocToFile(Mode[] _modes, char _key, String _parent){
    output.println("| "+_key+" |  for : "+_parent+" | Description |");
    output.println("|:---:|---|---|");
    int _index = 0;
    for(Mode _m : _modes){
      output.println("| `"+_index+"` | "+_m.getName()+" | "+_m.getDescription()+" |");
      _index++;
    }
    output.println(" ");
  }

}
