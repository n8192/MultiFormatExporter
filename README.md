# Multi-Format Exporter Script for 3ds Max

## Motivation

I wrote this script because I wanted to have the possibility to export meshes to other programs.

## Introduction

This is a script for 3ds Max, whose purpose is to export meshes, materials and animations in one of the available formats: Wavefront .obj, DirectX .x, or Collada .dae.

The script is best suited for exporting low- to mid-poly meshes.

The difference between this exporter and others is that it is written as a script, and due to this it is easy to modify and extend. You don't need the Max SDK or a specific C++ compiler to make changes to the exporter's code.

The script is compatible with very old 3ds Max version, and should also be compatible with more recent versions. I have not tested it.

If you find some incompatibility, it is your task to understand the problem and fix the script.

## Installation

1. Download the MultiFormatExporter.ms and place the script in the (3ds Max folder)\scripts\startup folder. Placing a script in this folder means that 3ds Max runs these scripts at startup. After this you will find the SceneFile helper in the Helpers tab. This is a helper object which you will use for exporting data.

2. I recommend increasing the default MAXScript heap size to 100–200 MB. You can do it in the Preferences dialog box. This allows scripts to use more memory and lowers the risk of getting an "out of memory" error.

## How to export data using the script

1. Go to the Helpers tab, select the SceneFile helper and place it somewhere in the scene. This helper is the tool for exporting data.

2. Rename the helper's name from the default name (like SceneFile01) to the base name of your desired output file name. For example, if you want to export data to the file Hero.dae, the helper name should be Hero. The helper uses this name when creating output file names.

3. Select the file format and file variant. If you need to export the scene as static geometry, select Static mesh. If you need to export a model but without animations, you can select Animated mesh only. If you want to export a skinned mesh, you can select only the mesh node; bones will be included without explicit selection.

4. Customize the export by selecting other options: Y-up axis, scaling, mesh components, animation clips.

5. By using the Add All or Select and Add buttons from the helper's UI, you start the exporting process. From selected nodes, output file(s) are generated and finally stored in the helper data.

   Note: There is no progress bar indicator. When the helper finishes its task, the name of the output file will be displayed inside the Contents frame.

6. To save the generated file(s), please use the Save button.

7. To finish the process - and free allocated memory - please click the Delete button. If you don't free the memory, the generated file will be stored in the scene file as part of the helper's data. This increases the size of the scene and is not necessary for typical purposes.

8. If you encounter a MAXScript "out of memory" error (or other error), please do not save the scene.

## Exportable scene elements

- Geometry: meshes and skinned meshes (only Skin Modifier is supported), multiple UV sets, options for generating vertex normal, tangent and bi-tangent vectors

- Materials: Multi-Material, Standard Material and Bitmap map

- Animations: node transforms (as matrix or decomposed)

## Output file formats

- Wavefront .obj

- DirectX .x

- Collada .dae

## Script author

Andrzej Chomiak

## License

The script is available under the ZLIB license.

## User interface

![](images/mfe_ui_v10.png)
