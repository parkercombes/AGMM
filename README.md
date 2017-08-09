
# AGMM
Auto generate a mind map from a directory structure and its files

This project has begun out of a desire to understand the XML structure behind Microsoft PowerPoint files i.e. pptx.  The structure of the directory and files is quite complicated, especially as you add more and more features to a slide deck.  

The project will start with an existing .pptx file and do the following: 
  1. unzip it into a local directory
  1. traverse that directory and map all directories, subdirectories, and files
  1. as each file is reviewed, find the references to other files and keep track of them
  1. as all of the hierarchies and references are tracked
      1. first 
      1. other types of files and references will take time 
  1. an XML file is built that will work with [freeplane](http:freeplane.org) to visually show the sturctures
