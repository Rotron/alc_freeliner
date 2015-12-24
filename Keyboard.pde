/**
 * ##copyright##
 * See LICENSE.md
 *
 * @author    Maxime Damecour (http://nnvtn.ca)
 * @version   0.3
 * @since     2014-12-01
 */

/**
 * Manage a keyboard
 * <p>
 * KEYCODES MAPPING
 * ESC unselect
 * CTRL feather mouse + (ctrl)...
 * UP DOWN LEFT RIGHT move snapped or previous point, SHIFT for faster
 * TAB tab through segmentGroups, SHIFT to reverse
 * BACKSPACE remove selected segment
 * <p>
 * CTRL + KEYS MAPPING
 * ctrl-a   selectAll
 * ctrl-c   clone A -> B
 * ctrl-b   all that has A gets B
 * ctrl-i   revers mouseX
 * ctrl-r   reset template
 * ctrl-d   customShape
 * ctrl-s   save
 * ctrl-o   open
 */

class Keyboard implements FreelinerConfig{
  //provides strings to show what is happening.
  final String KEY_MAP[] = {
    "a    animationMode",
    "b    renderMode",
    "c    placeCenter",
    "d    setShape",
    "e    enterpolator",
    "f    fillColor",
    "g    grid/size",
    "h    easingMode",
    "i    repetitonMode",
    "j    reverseMode",
    "k    strokeAlpha",
    "l    fillAlpha",
    "m    breakLine",
    "n    newItem",
    "o    rotation",
    //"p    probability??",
    "q    strkColor",
    "r    polka",
    "s    size",
    "t    tempo",
    "u    enabler",
    "v    segmentSelector",
    "w    strkWeigth",
    "x    beatMultiplier",
    "y    tracers",
    //"z    ???????",
    ",    showTags",
    "/    showLines",
    ";    showCrosshair",
    ".    snapping",
    "|    enterText",
    "]    fixedLenght",
    "[    fixedAngle",
    "-    decreaseValue",
    "=    increaseValue",
    "$    saveTemplate",
    "%    loadTemplate",
    "*    record",
    ">    steps"
  };

  final String CTRL_KEY_MAP[] = {
    "a    selectAll",
    "c    clone",
    "b    groupAddTemplate",
    "d    customShape",
    "i    reverseMouse",
    "r    resetTemplate",
    "s    saveStuff",
    "o    loadStuff",
    "l    loadLED",
    "k    showLEDmap"
  };

  // dependecy injection
  GroupManager groupManager;
  TemplateManager templateManager;
  TemplateRenderer templateRenderer;
  Gui gui;
  Mouse mouse;
  FreeLiner freeliner;

  //key pressed
  boolean shifted;
  boolean ctrled;
  boolean alted;

  // more keycodes
  final int CAPS_LOCK = 20;

  // flags
  boolean enterText;

  //setting selector
  char editKey = ' '; // dispatches number maker to various things such as size color
  char editKeyCopy = ' ';

  //user input int and string
  String numberMaker = "";
  String wordMaker = "";


/**
 * Constructor inits default values
 */
  public Keyboard(){
    shifted = false;
    ctrled = false;
    alted = false;
    enterText = false;
  }

/**
 * Dependency injection
 * Receives references to the groupManager, templateManager, GUI and mouse.
 *
 * @param GroupManager reference
 * @param TemplateManager reference
 * @param TemplateRenderer reference
 * @param Gui reference
 * @param Mouse reference
 */
  public void inject(FreeLiner _fl){
    freeliner = _fl;
    groupManager = freeliner.getGroupManager();
    templateManager = freeliner.getTemplateManager();
    templateRenderer = freeliner.getTemplateRenderer();
    gui = freeliner.getGui();
    mouse = freeliner.getMouse();
  }

/**
 * receive and key and keycode from papplet.keyPressed();
 *
 * @param char key that was press
 * @param int the keyCode
 */
  public void processKey(char k, int kc) {
    gui.resetTimeOut(); // was in update, but cant rely on got input due to ordering
    processKeyCodes(kc); // TAB SHIFT and friends
    // if in text entry mode
    if (enterText) {
      if (k==ENTER) returnWord();
      else if (k!=65535) wordMaker(k);
      println("Making word:  "+wordMaker);
      gui.setValueGiven(wordMaker);
    }
    else {
      if (k >= 48 && k <= 57) numMaker(k); // grab numbers into the numberMaker
      else if (k>=65 && k <= 90) processCAPS(k); // grab uppercase letters
      else if (k==ENTER) returnNumber(); // grab enter
      else if (ctrled || alted) modCommands(char(kc)); // alternate mappings related to ctrl and alt combos
      else{
        setEditKey(k, KEY_MAP);
        distributor(k, -3, true);
      }
    }
    //this should be elsewhere...
    if(editKey == '>') {
      gui.setTemplateString(templateManager.getSynchroniser().getStepToEdit().getTags()); // updates the tags to the ones of the sequencer
    }
  }


/**
 * Process keycode for keys like ENTER or ESC
 *
 * @param int the keyCode
 */
  public void processKeyCodes(int kc) {
    if (kc == SHIFT) shifted = true;
    else if (kc == ESC || kc == 27) unSelectThings();
    else if (kc==CONTROL) setCtrled(true);
    else if (kc==ALT) setAlted(true);
    else if (kc==UP) groupManager.nudger(false, -1, shifted);
    else if (kc==DOWN) groupManager.nudger(false, 1, shifted);
    else if (kc==LEFT) groupManager.nudger(true, -1, shifted);
    else if (kc==RIGHT) groupManager.nudger(true, 1, shifted);
    //tab and shift tab throug groups
    else if (kc==TAB) groupManager.tabThrough(shifted);
    else if (kc==BACKSPACE) backspaceAction();
    //else if (kc==32 && OSX) mouse.press(3); // for OSX people with no 3 button mouse.
  }

  private void backspaceAction(){
    // if (enterText) {
    //   wordMaker = removeLetter(wordMaker);
    // }
    // else if(numberMaker.length() > 0) numberMaker = removeLetter(numberMaker);
    // else
    if (!enterText) groupManager.deleteSegment();
  }

/**
 * Process key release, mostly affecting coded keys
 *
 * @param char the key
 * @param int the keyCode
 */
  public void processRelease(char k, int kc) {
    if (kc==16) shifted = false;
    else if (kc==17) ctrled = false;
    else if (kc==18) alted = false;
  }

  public void forceRelease(){
    shifted = false;
    ctrled = false;
    alted = false;
  }


  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Interpretation
  ///////
  ////////////////////////////////////////////////////////////////////////////////////
/**
 * Process capital letters. A trick is applied here, different actions happen if caps-lock is on or shift is pressed.
 * <p>
 * When shift is used it will toggle the renderer from a segment group or from the list.
 * When caps lock is used, it triggers the renderer. This way you can mash your keyboard with capslock on to perform.
 *
 * @param char the capital key to process
 */
  public void processCAPS(char _c) {
    TemplateList tl = groupManager.getTemplateList();

    if(editKey == '>') tl = templateManager.getSynchroniser().getStepToEdit();
    if(tl == null) tl = templateManager.getTemplateList();
    if(shifted){
      tl.toggle(templateManager.getTemplate(_c));
      groupManager.setReferenceGroupTemplateList(tl);
    }
    else {
      templateManager.trigger(_c);
      if(tl != groupManager.getTemplateList()){
        tl.clear();
        tl.toggle(templateManager.getTemplate(_c));
      }
    }
    gui.setTemplateString(tl.getTags());
  }


/**
 * The ESC key triggers this, it unselects segment groups / renderers, a second press will hid the gui.
 */
  private void unSelectThings(){
    if(!groupManager.isFocused() && !templateManager.isFocused()) gui.hide();
    else {
      templateManager.unSelect();
      groupManager.unSelect();
      gui.setTemplateString(" ");//templateManager.renderList.getString());
      groupManager.setReferenceGroupTemplateList(null);
    }
    // This should fix some bugs.
    alted = false;
    ctrled = false;
    shifted = false;
    editKey = ' ';
    gui.setKeyString("unselect");
    gui.setValueGiven(" ");
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Interpretation
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

//for some reason if you are holding ctrl or alt you get other keycodes
/**
 * Process a key differently if ctrl or alt is pressed.
 *
 * @param int ascii value of the key
 */
  public void modCommands(char _k){
    _k+=32;
    println("Mod : "+_k);
    // quick fix for ctrl-alt in OSX
    boolean _ctrl = ctrled;
    if(OSX) {
      _ctrl = alted;
      //_k-=96;
    }
    if (_k == 'a') focusAll();
    else if(_k == 'c') templateManager.copyTemplate();
    else if(_k == 'v') templateManager.pasteTemplate();
    else if(_k == 'b') templateManager.groupAddTemplate(); // ctrl-b
    else if(_k == 'd') distributor(char(504), -3, false);  // set custom shape
    else if(_k == 'i') gui.setValueGiven( str(mouse.toggleInvertMouse()) );
    else if(_k == 'r') distributor(char(518), -3, false);
    else if(_k == 'l') freeliner.reParse();
    else if(_k == 'k') freeliner.toggleExtraGraphics();
    else if(_k == 's') saveStuff();
    else if(_k == 'o') loadStuff();
    else return;
    gui.setKeyString(getKeyString(_k, CTRL_KEY_MAP));
  }

/**
 * Checks if the key is mapped by checking the keyMap to see if is defined there.
 *
 * @param char the key
 */
  boolean keyIsMapped(char _k, String[] _map) {
    for (int i = 0; i < _map.length; i++) {
      if (_map[i].charAt(0) == _k) return true;
    }
    return false;
  }

/**
 * Gets the string associated to the key from the keyMap
 *
 * @param char the key
 */
  String getKeyString(char _k, String[] _map) {
    for (int i = 0; i < _map.length; i++) {
      if (_map[i].charAt(0) == _k) return _map[i];
    }
    return "not mapped?";
  }


/**
 * CTRL-a selects all renderers as always.
 */
  private void focusAll(){
    groupManager.unSelect();
    templateManager.focusAll();
    gui.setTemplateString("*all*");
    wordMaker = "";
    enterText = false;
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Distribution of input to things
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

  //distribute input!
  //check if its mapped to general things
  //then if an item has focus
  //check if it is mapped to an item thing
  //if not then pass it to the first decorator of the item.
  //if no item has focus, pass it to the slected renderers.

  public void distributor(char _k, int _n, boolean _vg){
    if (!localDispatch(_k, _n, _vg)){
      SegmentGroup sg = groupManager.getSelectedGroup();
      TemplateList tl = null;
      if(sg != null){
        if(!segmentGroupDispatch(sg, _k, _n, _vg)) tl = sg.getTemplateList();
      }
      else tl = templateManager.getTemplateList();
      if(tl != null){
        ArrayList<TweakableTemplate> templates = tl.getAll();
        if(templates != null)
          for(TweakableTemplate te : templates)
            rendererDispatch(te, _k, _n, _vg);
      }
    }
  }


  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Dispatches
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

  // PERHAPS MOVE
  // for the signature ***, char k, int n, boolean vg
  // char K is the editKey
  // int n, -3 is no number, -2 is decrease one, -1 is increase one and > 0 is value to set.
  // boolean vg is weather or not to update the value given. (osc?)

  public boolean localDispatch(char _k, int _n, boolean _vg) {
    boolean used_ = true;
    String valueGiven_ = null;
    if(_n == -3){
      if (_k == 'n'){
        groupManager.newGroup();
        gui.updateReference();
      }
      else if (_k == 'm') mouse.press(3);
      else if (_k == 't') templateManager.sync.tap();
      else if (_k == 'g') valueGiven_ = str(mouse.toggleGrid());
      else if (_k == 'y') valueGiven_ = str(templateRenderer.toggleTrails());
      else if (_k == '*') valueGiven_ = str(toggleRecording());
      else if (_k == ',') valueGiven_ = str(gui.toggleViewTags());
      else if (_k == '.') valueGiven_ = str(mouse.toggleSnapping());
      else if (_k == '/') valueGiven_ = str(gui.toggleViewLines());
      else if (_k == ';') valueGiven_ = str(gui.toggleViewPosition());
      else if (_k == '|') valueGiven_ = str(toggleEnterText());
      else if (_k == '-') distributor(editKey, -2, _vg); //decrease value
      else if (_k == '=') distributor(editKey, -1, _vg); //increase value
      else if (_k == ']') valueGiven_ = str(mouse.toggleFixedLength());
      else if (_k == '[') valueGiven_ = str(mouse.toggleFixedAngle());
      //else if (_k == '!') valueGiven_ = str(templateManager.toggleLooping());
      // else if (_k == '@') saveStuff();
      // else if (_k == '#') loadStuff();
      else if (_k == '?') templateManager.getSynchroniser().clear();
      else used_ = false;
    }
    else {
      if (editKey == 'g') valueGiven_ = str(mouse.setGridSize(_n));
      else if (editKey == 't') templateManager.sync.nudgeTime(_n);
      else if (editKey == 'y') valueGiven_ = str(templateRenderer.setTrails(_n));
      else if (editKey == ']') valueGiven_ = str(mouse.setLineLenght(_n));
      else if (editKey == '[') valueGiven_ = str(mouse.setLineAngle(_n));
      else if (editKey == '.') valueGiven_ = str(groupManager.setSnapDist(_n));
      else if (editKey == '>') valueGiven_ = str(templateManager.getSynchroniser().setEditStep(_n));
      else used_ = false;
    }

    if(_vg && valueGiven_ != null) gui.setValueGiven(valueGiven_);
    return used_;
  }


  /**
   * Distribute parameters for segmentGroups, such as place center, set scalar, or grab as cutom shape
   * @param SegmentGroup segmentGroup to affect
   * @param char editKey (like q for color)
   * @param int value to set
   * @param boolean display the valueGiven in the gui.
   * @return boolean if the key was used.
   */
  public boolean segmentGroupDispatch(SegmentGroup _sg, char _k, int _n, boolean _vg) {
    boolean used_ = true;
    String valueGiven_ = null;
    if(_k == 'c') valueGiven_ = str(_sg.toggleCenterPutting());
    else if(_k == 's') valueGiven_ = str(_sg.setBrushScaler(_n));
    //else if(_k == '.') valueGiven_ = str(_sg.setSnapVal(_n));
    else if (int(_k) == 504) templateManager.setCustomShape(_sg);
    else used_ = false;
    if(_vg && valueGiven_ != null) gui.setValueGiven(valueGiven_);
    return used_;
  }

  /**
   * Control parameters via OSC, bypassing gui stuff.
   * @param String template tags (like ABC)
   * @param char editKey (like q for color)
   * @param int value to set
   */
  public void oscDistribute(String _tags, char _k, int _n){
    if(_tags.charAt(0) == '*'){
      for(TweakableTemplate _tw : templateManager.getTemplates()){
        if( _tw != null) rendererDispatch(_tw, _k, _n, false);
      }
    }
    else {
      for(int i = 0; i < _tags.length(); i++){
        TweakableTemplate _rt = templateManager.getTemplate(_tags.charAt(i));
        if(_rt != null){
          rendererDispatch(_rt, _k, _n, false);
        }
      }
    }
  }


  public boolean rendererDispatch(TweakableTemplate _template, char _k, int _n, boolean _vg) {
    //println(_template.getID()+" "+_k+" ("+int(_k)+") "+n);
    boolean used_ = true;

    if(_template != null){
      String valueGiven_ = null;
      if(_n == -3){
        if (_k == '$') _template.saveToBank();
        else if (int(_k) == 518) _template.reset();
        else used_ = false;
      }
      else {
        if (_k == 'a') valueGiven_ = str(_template.setAnimationMode(_n));
        else if (_k == 'b') valueGiven_ = str(_template.setRenderMode(_n));
        else if (_k == 'd') valueGiven_ = str(_template.setBrushMode(_n));
        else if (_k == 'f') valueGiven_ = str(_template.setFillMode(_n));
        else if (_k == 'h') valueGiven_ = str(_template.setEasingMode(_n));
        else if (_k == 'i') valueGiven_ = str(_template.setRepetitionMode(_n));
        else if (_k == 'j') valueGiven_ = str(_template.setReverseMode(_n));
        else if (_k == 'k') valueGiven_ = str(_template.setStrokeAlpha(_n));
        else if (_k == 'l') valueGiven_ = str(_template.setFillAlpha(_n));
        else if (_k == 'o') valueGiven_ = str(_template.setRotationMode(_n));
        else if (_k == 'e') valueGiven_ = str(_template.setInterpolateMode(_n));
        else if (_k == 'q') valueGiven_ = str(_template.setStrokeMode(_n));
        else if (_k == 'r') valueGiven_ = str(_template.setRepetitionCount(_n));
        else if (_k == 's') valueGiven_ = str(_template.setBrushSize(_n));
        else if (_k == 'u') valueGiven_ = str(_template.setEnablerMode(_n));
        else if (_k == 'v') valueGiven_ = str(_template.setSegmentMode(_n));
        else if (_k == 'w') valueGiven_ = str(_template.setStrokeWidth(_n));
        else if (_k == 'x') valueGiven_ = str(_template.setBeatDivider(_n));
        else if (_k == '%') valueGiven_ = str(_template.setBankIndex(_n));
        else used_ = false;
      }
      if(_vg && valueGiven_ != null) gui.setValueGiven(valueGiven_);
    }
    return used_;
  }


  public boolean toggleRecording(){
    boolean record = templateRenderer.toggleRecording();
    templateManager.getSynchroniser().setRecording(record);
    return record;
  }

  public void saveStuff(){
    groupManager.saveGroups();
    templateManager.saveTemplates();
  }
  public void loadStuff(){
    groupManager.loadGroups();
    templateManager.loadTemplates();
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Typing in stuff
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

  /**
   * Add a char to the text entry
   * @param char to add
   */
  private void wordMaker(char _k) {
    if(wordMaker.length() < 1) wordMaker = str(_k);
    else wordMaker = wordMaker + str(_k);
  }

  private String removeLetter(String _s){
     if(_s.length() > 1){
       return _s.substring(0, _s.length()-1 );
     }
     return "";
   }



  private void returnWord() {
    SegmentGroup _sg = groupManager.getSelectedGroup();
    if (groupManager.getSnappedSegment() != null) groupManager.getSnappedSegment().setText(wordMaker);
    wordMaker = "";
    enterText = false;
  }


  // type in values of stuff
  private void numMaker(char _k) {
    if(numberMaker.length() < 1) numberMaker = str(_k);
    else numberMaker = numberMaker + str(_k);
    if(numberMaker.charAt(0) == '0' && numberMaker.length()>1) numberMaker = numberMaker.substring(1);
    gui.setValueGiven(numberMaker);
  }

  private void returnNumber() {
    try {
      distributor(editKey, Integer.parseInt(numberMaker), true);
    }
    catch (Exception e){
      println("Bad number string");
    }
    numberMaker = "";
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Modifiers
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

  /**
   * Set the editKey
   * The edit key is very important, it selects what parameter to modify.
   * This also verbose the parameter in the GUI.
   * @param char the edit Key
   */
  public void setEditKey(char _k, String[] _map) {
    if (keyIsMapped(_k, _map) && _k != '-' && _k != '=') {
      gui.setKeyString(getKeyString(_k, _map));
      editKey = _k;
      numberMaker = "0";
      gui.setValueGiven("_");
    }
  }

  /**
   * Set if the ctrl key is pressed. Also sets the mousePointer origin to feather the mouse movement for non OSX.
   * @param boolean ctrl key status
   */
  public void setCtrled(boolean _b){
    if(_b){
      ctrled = true;
      if(!OSX) mouse.setOrigin();
    }
    else ctrled = false;
  }

  /**
   * Set if the alt key is pressed. Also sets the mousePointer origin to feather the mouse movement for OSX.
   * @param boolean alt key status
   */
  public void setAlted(boolean _b){
    if(_b){
      alted = true;
      if(OSX) mouse.setOrigin();
    }
    else alted = false;
  }

  /**
   * Toggle text entry
   * @return boolean valueGiven
   */
  public boolean toggleEnterText(){
    enterText = !enterText;
    return enterText;
  }


  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Accessors
  ///////
  ////////////////////////////////////////////////////////////////////////////////////
  /**
   * Is the ctrl key pressed? In OSX the ctrl key behavior is given to the alt key...
   * @return boolean valueGiven
   */
  public boolean isCtrled(){
    if(OSX) return alted;
    return ctrled;
  }

  public boolean isAlted(){
    return alted;
  }

  public boolean isShifted(){
    return shifted;
  }

}
