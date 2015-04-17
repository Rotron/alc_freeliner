/**
 *
 * ##copyright##
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 *
 * @author    Maxime Damecour (http://nnvtn.ca)
 * @version   0.1
 * @since     2014-12-01
 */


/**
 * Manage segmentGroups!
 *
 */
class GroupManager{

  //selects groups to control, -1 for not selected
  int selectedIndex;
  int lastSelectedIndex;
  int snappedIndex;
  int snapDist = 15;
  // list of PVectors that are snapped
  ArrayList<PVector> snappedList;

  //manages groups of points
  ArrayList<SegmentGroup> groups;
  int groupCount = 0;

/**
 * Constructor, inits default values
 */
  public GroupManager(){
  	groups = new ArrayList();
    snappedList = new ArrayList();
  	groupCount = 0;
    selectedIndex = -1;
    lastSelectedIndex = -1;
    snappedIndex = -1;
    newGroup();
  }


  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Actions
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

/**
 * Create a new group.
 */
  public void newGroup() {
    groups.add(new SegmentGroup(groupCount));
    selectedIndex = groupCount;
    groupCount++;
  }

/**
 * Tab the focus through groups.
 * @param boolean reverse direction (shift+tab) 
 */
  public void tabThrough(boolean _shift) {
    if(!isFocused()) selectedIndex = lastSelectedIndex;
    else if (_shift) selectedIndex--;
    else selectedIndex++;
    selectedIndex = wrap(selectedIndex, groupCount-1);
  }

/**
 * Add an other renderer to all groups who have the first renderer.
 * @param renderer to add
 * @param renderer to match
 */
  public void groupAddTemplate(TweakableTemplate _toAdd, TweakableTemplate _toMatch){
    if(groups.size() > 0 && _toAdd != null && _toMatch != null){
      for (SegmentGroup sg : groups) {
        TemplateList tl = sg.getTemplateList();
        if(tl != null)
          if(tl.contains(_toMatch))         
            tl.toggle(_toAdd);
      }
    }
  }



/**
 * Snap puts all the PVectors that are near the position given into a arrayList.
 * The snapDist can be adjusted like anything else. 
 * It returns the place it snapped to to adjust cursor.
 * @param PVector of the cursor
 * @return PVector where it snapped.
 */
  public PVector snap(PVector _pos){
    PVector snap = new PVector(0, 0);
    snappedList.clear();
    snappedIndex = -1;
    ArrayList<Segment> segs;
    for (int i = 0; i < groupCount; i++) {
      segs = groups.get(i).getSegments();
      // check if snapped to center
      if(_pos.dist(groups.get(i).getCenter()) < snapDist){
        snappedList.add(groups.get(i).getCenter());
        snap = groups.get(i).getCenter();
        snappedIndex = i;    
      }
      for(Segment seg : segs){
        if(_pos.dist(seg.getRegA()) < snapDist){
          snappedList.add(seg.getRegA());
          snap = seg.getRegA();
          snappedIndex = i;        }
        else if(_pos.dist(seg.getRegB()) < snapDist){
          snappedList.add(seg.getRegB());
          snap = seg.getRegB();
          snappedIndex = i;
        }
      }
    }    
    if (snappedIndex != -1){
      if(selectedIndex == -1) lastSelectedIndex = snappedIndex; 
      return snap;// snappedList.get(0);
    }
    else return _pos;
  }

/**
 * Nudge all PVectors of the snappedList.
 * If the snapped list is empty and we are focused on a group, nudge the segmentStart.
 * @param boolean verticle/horizontal
 * @param int direction (1 or -1)
 * @param boolean nudge 10X more
 */
  public void nudger(Boolean axis, int dir, boolean _shift){
    PVector ndg = new PVector(0, 0);
    if(_shift) dir*=10;
    if (axis) ndg.set(dir, 0);
    else ndg.set(0, dir);
    if(snappedList.size()>0){
      for(PVector _pv : snappedList){
        _pv.add(ndg);
      }
      //setCenter(center);
      reCenter();
    }
    else if(isFocused()) getSelectedGroup().nudgeSegmentStart(ndg);
  }

  private void reCenter(){
    for(SegmentGroup sg : groups)
      sg.placeCenter(sg.getCenter());
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Save and load prototypes
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

/**
 * Basic way to save all the coordinates that have been layed out.
 * Saves to a xml file.
 * May we will save entire groups and stuff soon.
 */  
  // public void saveVertices(){
  //   ArrayList<PVector> pnts = new ArrayList();
  //   for(SegmentGroup grp : groups){
  //     ArrayList<Segment> segs = grp.getSegments(); 
  //     for(Segment seg : segs){
  //       if(!isDuplicate(pnts, seg.getRegA())) pnts.add(seg.getRegA());
  //       if(!isDuplicate(pnts, seg.getRegB())) pnts.add(seg.getRegB());
  //     }
  //   }
  //   XML vertices = new XML("vertices");
  //   //toSave.removeChild(toSave.getChild("vertices"));
  //   for(PVector pnt : pnts){
  //     XML vertx = vertices.addChild("vertex");
  //     vertx.setFloat("x", pnt.x);
  //     vertx.setFloat("y", pnt.y);
  //   }
  //   saveXML(vertices, "data/vertices.xml");
  // }

  public void saveGroups(){
    //ArrayList<PVector> pnts = new ArrayList();
    XML groupData = new XML("groups");
    for(SegmentGroup grp : groups){
      XML xgroup = groupData.addChild("group");
      xgroup.setInt("ID", grp.getID());
      xgroup.setFloat("centerX", grp.getCenter().x);
      xgroup.setFloat("centerY", grp.getCenter().y);
      for(Segment seg : grp.getSegments()){
        XML xseg = xgroup.addChild("segment");
        xseg.setFloat("aX",seg.getA().x);
        xseg.setFloat("aY",seg.getA().y);
        xseg.setFloat("bX",seg.getB().x);
        xseg.setFloat("bY",seg.getB().y);
      }
      saveXML(groupData, "data/groups.xml");
    }
  }


  public void loadGroups(){
    XML file;
    try {
      file = loadXML("data/groups.xml");
    }
    catch (Exception e){
      println("No groups.xml");
      return;
    }
    XML[] groupData = file.getChildren("group");
    PVector posA = new PVector(0,0);
    PVector posB = new PVector(0,0);
    boolean first = true;
    for(XML xgroup : groupData){
      if(first){
        first = false;
        continue;
      }
      newGroup();
      XML[] xseg = xgroup.getChildren("segment");
      for(XML seg : xseg){
        posA.set(seg.getFloat("aX"), seg.getFloat("aY"));
        posB.set(seg.getFloat("bX"), seg.getFloat("bY"));
        getSelectedGroup().addSegment(posA.get(), posB.get()); 
      }
      getSelectedGroup().mouseInput(LEFT, posB);
      getSelectedGroup().setNeighbors();
      posA.set(xgroup.getFloat("centerX"), xgroup.getFloat("centerY"));
      if(abs(posA.x - getSelectedGroup().getSegment(0).getA().x) > 2) getSelectedGroup().placeCenter(posA);
    }
  }

  public void loadVertices(){
    XML file;
    try {
      file = loadXML("data/vertices.xml");
    }
    catch (Exception e){
      println("No vertices.xml");
      return;
    }
    XML[] vertices = file.getChildren("vertex");
    newGroup();
    PVector pos = new PVector(0,0);
    for(XML vert : vertices){
      pos.set(vert.getFloat("x"), vert.getFloat("y"));
      getSelectedGroup().mouseInput(LEFT, pos);
    }
  }



// /**
//  * Check if a coordinate has already been added to a list.
//  * @param ArrayList<PVector> to check
//  * @param PVector in question
//  * @return boolean
//  */  
//   private boolean isDuplicate(ArrayList<PVector> _pnts, PVector _pv){
//     for(PVector pnt : _pnts){
//       if(pnt.dist(_pv) < 0.001) return true;
//     }
//     return false;
//   }

/**
 * Loads a previously generated xml file into one group to provide snapping points.
 */  
  // public void loadVertices(){
  //   XML file;
  //   try {
  //     file = loadXML("data/vertices.xml");
  //   }
  //   catch (Exception e){
  //     println("No vertices.xml");
  //     return;
  //   }
  //   XML[] vertices = file.getChildren("vertex");
  //   newGroup();
  //   PVector pos = new PVector(0,0);
  //   for(XML vert : vertices){
  //     pos.set(vert.getFloat("x"), vert.getFloat("y"));
  //     getSelectedGroup().mouseInput(LEFT, pos);
  //   }
  // }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Modifiers
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

/**
 * Unselect selected group
 */  
  public void unSelect(){
    lastSelectedIndex = selectedIndex;
    selectedIndex = -1;
  }

/**
 * Unselect selected group
 */  
  // public int setSelectedGroupIndex(int _i) {
  //   selectedIndex = _i % groupCount;
  //   return selectedIndex;
  // }

/**
 * Adjust the snapping distance.
 * @param int adjustement to make
 * @return int new value
 */  
  public int setSnapDist(int _i){
    snapDist = numTweaker(_i, snapDist);
    return snapDist;
  }

  // public void toggle(TemplateEvent _rn){
  //   renderList.toggle(_rn);
  // }

  ////////////////////////////////////////////////////////////////////////////////////
  ///////
  ///////     Accessors
  ///////
  ////////////////////////////////////////////////////////////////////////////////////

/**
 * Get renderList of the selected group, null if no group selected.
 * @return renderList
 */  
  public TemplateList getTemplateList(){
    SegmentGroup sg = getSelectedGroup();
    if(sg != null) return sg.getTemplateList();
    else return null;
  }

/**
 * Check if a group is focused
 * @return boolean 
 */  
  boolean isFocused(){
    if(snappedIndex != -1 || selectedIndex != -1) return true;
    else return false;
  }

/**
 * Get the selectedGroupIndex, will return -1 if nothing selected, used by gui
 * @return int index
 */  
  public int getSelectedIndex(){
    return selectedIndex;
  }

/**
 * Get the selectedGroup, or the snapped one, or null
 * @return SegmentGroup
 */ 
  public SegmentGroup getSelectedGroup(){
    if(snappedIndex != -1 && selectedIndex == -1) return groups.get(snappedIndex);
    else if(selectedIndex != -1 && selectedIndex <= groupCount) return groups.get(selectedIndex);
    else return null;
  }

/**
 * Get the previously selected group, or null
 * Used to set the previously selected group as a renderer's custom shape.
 * @return SegmentGroup
 */ 
  public SegmentGroup getLastSelectedGroup(){
    if(lastSelectedIndex != -1 ) return groups.get(lastSelectedIndex);
    else return null;
  }

/**
 * Get a specific group
 * @return SegmentGroup
 */
  public SegmentGroup getGroup(int _i){
    if(_i >= 0 && _i < groupCount) return groups.get(_i);
    else return null;
  }

/**
 * Get all the groups
 * @return SegmentGroup
 */
  public ArrayList<SegmentGroup> getGroups(){
    return groups;
  }

/**
 * Get the last point of a group
 * @return SegmentGroup
 */
  public PVector getPreviousPosition() {
    if (isFocused()) return getSelectedGroup().getLastPoint();
    else return new PVector(width/2, height/2, 0);
  }

}