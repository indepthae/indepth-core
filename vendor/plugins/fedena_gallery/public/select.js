(function() {


  FedenaSelector = {
    "select": function() {
      this.div_ids = [];
      this.allBindings = {};
      this.allFunction = [];
      this.div_ids = [];
      this.total_level;
      this.curr_selection_level = [];
      this.curr_selection_link= [];
      this.name;
      this.full_values;
      this.current_block = {};
      this.level_names = [];
      this.level_child_plural;
      this.temp_level;
      this.temp_block;
      this.temp_index;

      this.generate_select = function(name_param, values, function_list, div_ids_param, level_no, level_names_param,plural) {
        //object
        var level = {};
        this.name = name_param;
        this.allFunction = function_list;
        this.total_level = div_ids_param.length;
        this.div_ids = div_ids_param;
        this.level_names = level_names_param;
        this.level_child_plural=plural;
        level["b1"] = {
          list: [],
          parent_block: null,
          parent_index: null,
          count: 0
        };

        //bind element to level
        for (var i = 0; i < values.length; i++) {
          var element = {};
          element.value = values[i].value;
          element.id = values[i].id;
          element.child_count = values[i].child_count;
          element.selected = 0;
          level.b1.list.push(element);
        }
        this.generate_skeleton(level_no)

        this.allBindings[level_no] = level;
        this.refresh_level(level_no, "b1");


      };

      this.load_preset = function(privilege_json) {
        this.allBindings = JSON.parse(privilege_json);
        this.generate_skeleton(0);
        this.refresh_level(0, "b1");
      };

      this.nesting_create = function(link) {
        var level_no = parseInt(link.dataset.value);
        var node_level_elements = this.allBindings[level_no];
        var block = link.dataset.block;
        var index = parseInt(link.dataset.index);
        var collect_chain = [];

        //code for select option color
        if (this.curr_selection_level[level_no] != null) {
          var option = document.getElementById(this.curr_selection_level[level_no]);
          option.style.backgroundColor = "#ffffff";
          var arrow = document.getElementById(this.curr_selection_level[level_no]+"_arrow");
          arrow.style.display = "none";
          var link = document.getElementById(this.curr_selection_link[level_no]);
          link.style.display = "block";

          option = document.getElementById(this.name + "l" + level_no + "i" + index);
          option.style.backgroundColor = "#f2fffd";
          var arrow = document.getElementById(this.name + "l" + level_no + "i" + index+"_arrow");
          arrow.style.display = "block";
          var link = document.getElementById(this.name + level_no +block+ "sel" + index);
          link.style.display = "none";

          this.curr_selection_level[level_no] = this.name + "l" + level_no + "i" + index;
          this.curr_selection_link[level_no] = this.name + level_no +block+ "sel" + index;
        } else {
          var option = document.getElementById(this.name + "l" + level_no + "i" + index);
          option.style.backgroundColor = "#f2fffd";
          var arrow = document.getElementById(this.name + "l" + level_no + "i" + index+"_arrow");
          arrow.style.display = "block";

          var link = document.getElementById(this.name + level_no +block+ "sel" + index);
          link.style.display = "none";


          this.curr_selection_level[level_no] = this.name + "l" + level_no + "i" + index;
          this.curr_selection_link[level_no] = this.name + level_no +block+ "sel" + index;
        }


        this.hide_other_levels(level_no);

        var new_block = block + "b" + index;
        if (typeof(this.allBindings[level_no + 1]) == "undefined" || typeof(this.allBindings[level_no + 1][new_block]) == "undefined") {
          //bactracking
          var temp_level = level_no;
          var temp_block = block;
          var temp_index = index;
          while (temp_level >= 0) {
            var temp_element = this.allBindings[temp_level][temp_block]["list"][temp_index];
            collect_chain.push(temp_element.id);
            var curr_block = this.allBindings[temp_level][temp_block];
            //ready for next
            temp_level = temp_level - 1;
            temp_block = curr_block.parent_block;
            temp_index = curr_block.parent_index;
          }

          //get ready for generating next selector
          var next_values = this.allFunction[level_no](collect_chain);
          this.temp_level=level_no+1;
          this.temp_block=block;
          this.temp_index=index;

        } else {
          this.generate_next([], (level_no + 1), block, index);
        }

      };


      this.send_values=function(next_values){
        var level_no=this.temp_level;
        var block=this.temp_block;
        var index=this.temp_index;
        this.generate_next(next_values, level_no, block, index);
      };


      this.build_complete = function(values) {
        this.full_values = values;
        var level = {};
        var level_no = 0;
        level["b1"] = {
          list: [],
          parent_block: null,
          parent_index: null,
          count: 0
        };

        //bind element to level
        for (var i = 0; i < this.full_values[0].length; i++) {
          var element = {};
          element.value = this.full_values[0][i].value;
          element.id = this.full_values[0][i].id;
          if(typeof(this.full_values[0][i].child_count)!="undefined")
          {
            element.child_count= this.full_values[0][i].child_count;
          }
          element.selected = (typeof(this.full_values[0][i].selected) == "undefined" ? 0 : this.full_values[0][i].selected);
          level.b1.list.push(element);
        }
        this.generate_skeleton(level_no)

        this.allBindings[level_no] = level;
        this.refresh_level(level_no, "b1");
        this.set_count(level_no,"b1");

        this.build_child(level_no, "b1");
      };

      this.build_child = function(curr_level, curr_block) {
        var elements = this.allBindings[curr_level][curr_block]["list"];
        if (curr_level < (this.div_ids.length)) {
          for (var i = 0; i < elements.length; i++) {
            var element = this.allBindings[curr_level][curr_block]["list"][i];
            this.build_values(curr_level + 1, curr_block + "b" + i, curr_level, curr_block, element.id, i);
          }
        }
      };

      this.build_values = function(curr_level, curr_block, prev_level, prev_block, id, index) {
        if (typeof(this.allBindings[curr_level]) == "undefined") {
          var level = {};
          this.allBindings[curr_level] = level;
        }

        this.allBindings[curr_level][curr_block] = {
          list: [],
          parent_block: prev_block,
          parent_index: index,
          count: 0
        };

        var value_set = this.full_values[curr_level][id]
        for (var i = 0; i < value_set.length; i++) {
          var element = {};
          element.value = value_set[i].value;
          element.id = value_set[i].id;
          if(typeof(value_set[i].child_count)!="undefined")
          {
            element.child_count= value_set[i].child_count;
          }
          element.selected = value_set[i].selected;
          this.allBindings[curr_level][curr_block]["list"].push(element);
        }
        this.set_count(curr_level,curr_block);
        this.check_for_parent(curr_level, curr_block);
      };

      this.checked = function(field) {

        var level = parseInt(field.dataset.value);
        var block = field.dataset.block;
        var index = parseInt(field.dataset.index);
        var temp_element = this.allBindings[level][block]["list"][index];
        //confirm if alias is clicked or original
        var original = document.getElementById(this.name + level + block + "i" + index);
        if (field.checked == true) {
          temp_element.selected = 1;
          original.indeterminate = false;
          original.checked = true;

        } else {
          temp_element.selected = 0;
          original.indeterminate = false;
          original.checked = false;
        }
        this.check_for_child(level, block, index);
        this.check_for_parent(level, block);


        this.set_count(level, block);

        //set selected  tag if children are not loaded

            if((typeof(this.allBindings[level+1])=="undefined" ? true :  typeof(this.allBindings[level+1][block+"b"+index])=="undefined") ){
              var parent_count = document.getElementById(this.name + "_count_l" + (level) + "i" + index);
              if(parent_count!=null){
                var show_count= (field.checked == true) ? this.allBindings[level][block]["list"][index]["child_count"] : 0;
                parent_count.innerHTML = show_count + " selected ";
              }

            }



      };

      this.selected_values = function() {
        return this.allBindings;
      };

      this.set_count = function(level, block) {
        var elements = this.allBindings[level][block]["list"];
        var parent_index = this.allBindings[level][block]["parent_index"];
        var count = 0;
        var tick = false,
          nontick = false,
          partial = false;
        var header_checkbox_status;
        for (var i = 0; i < elements.length; i++) {
          if (elements[i].selected == 1 || elements[i].selected == 2) {
            count++;
          }
        }
        for (var i = 0; i < elements.length; i++) {
          switch (elements[i].selected) {
            case 0:
              nontick = true;
              break;
            case 1:
              tick = true;
              break;
            case 2:
              partial = true;
              break;
            default:
              console.log("Invalid checkbox state");
          }

          if (partial == true) {
            header_checkbox_status = 2;
            break;
          } else if (tick == true && nontick == true) {
            header_checkbox_status = 2;
            break;
          } else {

          }
        }


        if (tick == true && nontick == false && partial == false) {
          header_checkbox_status = 1;
        } else if (tick == false && nontick == true && partial == false) {
          header_checkbox_status = 0;
        } else {

        }



        this.allBindings[level][block]["count"] = count;
        //finding block in the view
        if (this.current_block[level] == block) {
          var count_top = document.getElementById(this.name + 'topcount' + level);
          count_top.innerHTML = count + " selected ";
          //setting header_checkbox
          var header_checkbox = document.getElementById(this.name + "_head_" + level);
          if (header_checkbox_status == 2) {
            header_checkbox.indeterminate = true;
          } else if (header_checkbox_status == 1) {
            header_checkbox.indeterminate = false;
            header_checkbox.checked = true;
          } else {
            header_checkbox.indeterminate = false;
            header_checkbox.checked = false;
          }
        }

        //set count to parent element
        if (level > 0) {
          if (this.current_block[level - 1] == this.allBindings[level][block]["parent_block"]) {
            var parent_count = document.getElementById(this.name + "_count_l" + (level - 1) + "i" + parent_index);
            parent_count.innerHTML = count + " selected ";

          }

        }


      }

      this.check_for_parent = function(curr_level, curr_block) {
        var elements = this.allBindings[curr_level][curr_block]["list"];

        var tick = false,
          nontick = false,
          partial = false;
        var status;
        for (var i = 0; i < elements.length; i++) {
          switch (elements[i].selected) {
            case 0:
              nontick = true;
              break;
            case 1:
              tick = true;
              break;
            case 2:
              partial = true;
              break;
            default:
              console.log("Invalid checkbox state");
          }
          if (partial == true) {
            status = 2;
            break;
          } else if (tick == true && nontick == true) {
            status = 2;
            break;
          } else {

          }

        }
        if (tick == true && nontick == false && partial == false) {
          status = 1;
        } else if (tick == false && nontick == true && partial == false) {
          status = 0;
        } else {

        }


        //assign status for parent
        if (curr_level > 0) //level 1 has no parent
        {
          var block = this.allBindings[curr_level][curr_block];
          this.allBindings[curr_level - 1][block.parent_block]["list"][block.parent_index].selected = status;
          var check = document.getElementById(this.name + (curr_level - 1) + block.parent_block + "i" + block.parent_index);

          switch (status) {
            case 0:
              check.indeterminate = false;
              check.checked = false;
              break;
            case 1:
              check.indeterminate = false;
              check.checked = true;
              break;
            case 2:
              check.indeterminate = true;
              break;
            default:
              console.log("error in setting parent id");
          }

          this.set_count(curr_level - 1, block.parent_block)
          //for change in parent can cause change to parents parent
          this.check_for_parent(curr_level - 1, block.parent_block);
        }
      };

      this.check_for_child = function(curr_level, curr_block, curr_index) {
        var current_status = this.allBindings[curr_level][curr_block]["list"][curr_index].selected;
        if (current_status != 2) {
          //curr block + "b"+ id is child block

          var child_block = curr_block + "b" + curr_index;

          if (typeof(this.allBindings[curr_level + 1]) != "undefined") {
            var block = this.allBindings[curr_level + 1][child_block];

            if (typeof(block) != "undefined") {
              var elements = this.allBindings[curr_level + 1][child_block]["list"];
              for (var i = 0; i < elements.length; i++) {
                elements[i].selected = current_status;
                var check = document.getElementById(this.name + (curr_level + 1) + child_block + "i" + i);
                if (check != null) {
                  if (current_status == 1) {
                    check.checked = true;
                  } else {
                    check.checked = false;
                  }

                }
                this.set_count(curr_level + 1, child_block);
                this.check_for_child(curr_level + 1, child_block, i);
              }

            }
          }

        }


      }


      this.hide_other_levels = function(currlevel) {
        //hide remaining levels
        for (var i = currlevel + 1; i <= this.total_level; i++) {
          var level_container = document.getElementById(this.name + "level" + i);
          if (level_container != null) {
            level_container.style.display = "none";
            this.curr_selection_link[i]=null;
            this.curr_selection_level[i]=null;
          }
        }


      };


      this.generate_next = function(values, level_no, previous_block, previous_element_index) {
        //do this if level creation is required
        if (typeof(this.allBindings[level_no]) == "undefined") {
          var level = {};
          this.allBindings[level_no] = level;
        }
        var block = previous_block + "b" + previous_element_index;
        //do all this if block not yet generated
        if (typeof(this.allBindings[level_no][block]) == "undefined") {
          //bind element to level
          this.allBindings[level_no][block] = {
            list: [],
            parent_block: previous_block,
            parent_index: previous_element_index,
            count: 0
          };
          for (var i = 0; i < values.length; i++) {
            var element = {};
            element.value = values[i].value;
            element.id = values[i].id;
            element.child_count = values[i].child_count;
            element.selected = 0;

            this.allBindings[level_no][block]["list"].push(element);
          }

        }
        else{
          var list=this.allBindings[level_no][block]["list"];

          for(var i=0;i<list.length;i++)
          {
            list[i].filter=false;
          }

        }


        this.generate_skeleton(level_no);

        //setting up saved count
        var count = this.allBindings[level_no][block]["count"]
        var count_top = document.getElementById(this.name + 'topcount' + level_no);
        count_top.innerHTML = count + " selected ";

        this.refresh_level(level_no, block);
        //checking child for newly generated
        this.check_for_child(level_no - 1, previous_block, previous_element_index)
      };


      this.generate_skeleton = function(level_no) {
        //generate skeleton for select

        var l = level_no;
        var context = this;

        var display = "block";
        var selector_height = "";
        //level one -hide items
        if (level_no == 0) {
          display = "none";
          selector_height = "level_zero_height";
        }

        var skeleton = document.getElementById(this.div_ids[level_no]);
        skeleton.innerHTML = ' <div class="selector_box" id="' + this.name + 'level' + level_no +
          '"><div id="' + this.name + '_no_result' + level_no +'" class="no_match">No results found</div><div style="display:' + display + ';" class="selected_value_banner"><span class="prev_selection">'+(level_no==0 ? "" : this.level_names[level_no-1])+' </span><span id="' + this.name + "_prev_" + level_no + '" class="prev_selection_value">value</span></div><div class="selector_head"><input id=' + this.name + '_head_' + level_no + ' class="select_box head_checkbox" type="checkbox"> <div class="selector_name">Select ' + this.level_names[level_no] + '</div><div id="' + this.name + 'topcount' + level_no +
          '" class="selector_count">0 Selected </div></div><div class="selector_search_box"><div id=' + this.name + "_clear" + level_no + ' class="clear_text themed_text" data-value=' + level_no + '>clear</div><input placeholder="Search " class="selector_search" id=' + this.name + "_search" + level_no + ' data-value=' + level_no + ' type="text"></div><div id="' + this.name + 'selector_list' + level_no +
          '" class="selector_list ' + selector_height + '"></div> <div style="display:' + display + ';" class="done"><button class="solid_button" id="' + this.name + "_done_" + level_no + '">Done</button></div> </div>';

        //listen search box
        var searchbox = document.getElementById(this.name + "_search" + level_no);
        searchbox.addEventListener("input", function() {
          var active_block = context.current_block[level_no]
          //all elements
          var all_elements = context.allBindings[level_no][active_block]["list"];
          var current_text = this.value;
          if (current_text==""){
            var clear_tag =document.getElementById(context.name + "_clear" + level_no);
            clear_tag.style.display="none";
            var head_checkbox= document.getElementById(context.name+"_head_"+level_no);
            head_checkbox.style.visibility = "visible";
          }
          else{
            var clear_tag =document.getElementById(context.name + "_clear" + level_no);
            clear_tag.style.display="block";
            var head_checkbox= document.getElementById(context.name+"_head_"+level_no);
            head_checkbox.style.visibility = "hidden";
          }

          var no_result=true;
          for (var i = 0; i < all_elements.length; i++) {
            var text_value= "";
            text_value=text_value+ all_elements[i].value;
            text_value= text_value.toLowerCase();
            if (text_value.indexOf(current_text.toLowerCase()) !== -1 || current_text.length < 1) {
              all_elements[i]["filter"] = false;
              //found some result
              no_result=false;
            } else {
              all_elements[i]["filter"] = true;
            }
          }
          var no_result_tag=document.getElementById(context.name+"_no_result"+level_no);
          if(no_result){
            no_result_tag.style.display="block";
          }
          else {
            no_result_tag.style.display="none";
          }
          context.allBindings[level_no][active_block]["list"] = all_elements;
          context.refresh_level(level_no, active_block);
        });

        //clear for searchbox
         var clear_tag= document.getElementById(this.name+"_clear"+level_no);
         clear_tag.addEventListener("click",function () {
           var active_block = context.current_block[level_no]
           var all_elements = context.allBindings[level_no][active_block]["list"];

           var no_result_tag=document.getElementById(context.name+"_no_result"+level_no);
           no_result_tag.style.display="none";

           for (var i = 0; i < all_elements.length; i++) {
             all_elements[i]["filter"] = false;
           }
           var sbox=document.getElementById(context.name+"_search"+level_no);
           sbox.value="";
           var clear_tag =document.getElementById(context.name + "_clear" + level_no);
           clear_tag.style.display="none";
           context.refresh_level(level_no,active_block);
           var head_checkbox= document.getElementById(context.name+"_head_"+level_no);
           head_checkbox.style.visibility = "visible";
         });

        //done button
        var done_button = document.getElementById(this.name + "_done_" + level_no);
        done_button.addEventListener("click", function() {
          //reset select arrow and color
          var option = document.getElementById(context.curr_selection_level[(level_no-1)]);
          option.style.backgroundColor = "#ffffff";
          var arrow = document.getElementById(context.curr_selection_level[(level_no-1)]+"_arrow");
          arrow.style.display = "none";
          var link = document.getElementById(context.curr_selection_link[(level_no-1)]);
          link.style.display = "block";

          context.curr_selection_link[level_no-1]=null;
          context.curr_selection_level[level_no-1]=null;

          context.hide_other_levels(level_no - 1);
        });
      };
      this.set_saved_status = function(level_no, block) {
        var level = this.allBindings[level_no];
        for (var i = 0; i < level[block]["list"].length; i++) {
          var check = document.getElementById(this.name + (level_no) + block + "i" + i);
          var status = level[block]["list"][i].selected;
          switch (status) {
            case 0:
              check.indeterminate = false;
              check.checked = false;
              break;
            case 1:
              check.indeterminate = false;
              check.checked = true;
              break;
            case 2:
              check.indeterminate = true;
              break;
            default:
              console.log("error in setting saved status");
          }
        }
      };

      this.refresh_level = function(level_no, block) {
        this.current_block[level_no] = block;
        var level = this.allBindings[level_no];
        var box = document.getElementById(this.name + "selector_list" + level_no);
        var temp = "";
        var context = this;

        if (level_no < (this.total_level - 1)) {
          for (var i = 0; i < level[block]["list"].length; i++) {

            //filter
            var display = "";
            if (typeof(level[block]["list"][i].filter) != "undefined") {
              if (level[block]["list"][i].filter == true) {
                display = 'style="display:none"';
              }
            }


            temp += ' <div ' + display + ' class="selector_element" id="' + this.name + 'l' + level_no + 'i' + i + '"><div class="arrow" id="' + this.name + 'l' + level_no + 'i' + i +"_arrow"+ '"><svg xmlns="http://www.w3.org/2000/svg" viewBox="3477 922 24 24"><defs><style>.cls-1 {fill: #777;}.cls-2 { fill: none;}</style></defs><g id="ic_chevron_right_black_24px" transform="translate(3477 922)"><path id="Path_53" data-name="Path 53" class="cls-1" d="M10,6,8.59,7.41,13.17,12,8.59,16.59,10,18l6-6Z"/><path id="Path_54" data-name="Path 54" class="cls-2" d="M0,0H24V24H0Z"/></g></svg></div><div class="selector_checkbox"><input id="' + this.name + level_no + block + "i" + i + '"  data-value=' + level_no + ' data-block=' + block +
              ' data-index=' + i + ' class="select_box" value=' + level[block]["list"][i].id +
              ' type="checkbox" /></div><div class="element_details"><div class="element_value"> <label class="tag" for="' + this.name + level_no + block + "i" + i + '">' + level[block]["list"][i].value +
              '</label></div><div class="element_count" > <span id="' + this.name + '_count_l' + level_no + 'i' + i + '"> '+ level[block]["list"][i].child_count+" "+(( level[block]["list"][i].child_count>1 ) ? this.level_child_plural[level_no] : this.level_names[level_no+1] )+'</span> <div class="open_nesting"><span class="nesting_select" id="' + this.name + level_no + block + "sel" + i + '" data-value=' + level_no + ' data-block=' + block +
              ' data-index=' + i + '>Select</span> </div></div>  </div> </div>';


          }
          box.innerHTML = temp;
          for (var i = 0; i < level[block]["list"].length; i++) {
            // for select link
            (function() {
              var select_link = document.getElementById(context.name + level_no + block + "sel" + i);
              var currcontext = context;
              select_link.addEventListener("click", function() {
                currcontext.nesting_create(select_link);
              });
            })();
            (function() {
              var tick = document.getElementById(context.name + level_no + block + "i" + i);
              var currcontext = context;
              tick.addEventListener("change", function() {
                currcontext.checked(tick);
              });
            })();
          }

        } else {
          //last level without select type elements
          box.innerHTML = "";
          for (var i = 0; i < level[block]["list"].length; i++) {
            //filter
            var display = "";
            if (typeof(level[block]["list"][i].filter) != "undefined") {
              if (level[block]["list"][i].filter == true) {
                display = 'style="display:none"';
              }
            }

            box.innerHTML += ' <div ' + display + ' class="selector_element single" id="l' + level_no + 'i' + i + '" ><div class="selector_checkbox single"><input id="' + this.name + level_no + block + "i" + i + '" data-value=' + level_no + ' data-block=' + block + ' data-index=' + i +
              ' class="select_box" value=' + level[block]["list"][i].id + ' type="checkbox" /></div><div class="element_details single"><div class="element_value"> <label class="tag" for="' + this.name + level_no + block + "i" + i + '">' + level[block]["list"][i].value + '</label></div></div></div>';


          }

        }


        for (var i = 0; i < level[block]["list"].length; i++) {
          (function() {
            var tick = document.getElementById(context.name + level_no + block + "i" + i);
            var currcontext = context;
            tick.addEventListener("change", function() {
              currcontext.checked(tick);
            });
          })();
        }

        var parent_block=this.allBindings[level_no][block]["parent_block"];
        var parent_index=this.allBindings[level_no][block]["parent_index"];
        //set head text
        if(level_no>0)
        {
          var head_text= document.getElementById(this.name + "_prev_" + level_no);
          head_text.innerHTML=this.allBindings[level_no-1][parent_block]["list"][parent_index].value;
        }

        //set head checkbox
        var head_checkbox = document.getElementById(this.name + "_head_" + level_no);

        head_checkbox.dataset.value = level_no - 1;
        head_checkbox.dataset.block = parent_block;
        head_checkbox.dataset.index = parent_index;
        head_checkbox.addEventListener("change", function() {
          if (level_no > 0) {
            context.checked(head_checkbox);
          } else {
            //first level
            var elements = context.allBindings[0]["b1"]["list"];
            for (var i = 0; i < elements.length; i++) {
              var check = document.getElementById(context.name + 0 + "b1" + "i" + i);
              if (check != null) {
                if (this.checked == true) {
                  check.indeterminate = false;
                  check.checked = true;
                  elements[i].selected = 1;
                } else {
                  check.indeterminate = false;
                  check.checked = false;
                  elements[i].selected = 0;
                }
                context.set_count(0, "b1");

              }
              context.check_for_child(0, "b1", i);
            }

          }

        });
        this.set_saved_status(level_no, block);

        //set back selected
        if (this.curr_selection_level[level_no] != null) {
          var option = document.getElementById(this.curr_selection_level[level_no]);
          option.style.backgroundColor = "#f2fffd";
          var arrow = document.getElementById(this.curr_selection_level[level_no]+"_arrow");
          arrow.style.display = "block";
          var link = document.getElementById(this.curr_selection_link[level_no]);
          link.style.display = "none";
        }

      };



    }

  }


}).call(this);
