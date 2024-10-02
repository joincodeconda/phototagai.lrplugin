# PhotoTag.ai Metadata Generator for Lightroom Classic

The **PhotoTag.ai Metadata Generator** is a Lightroom Classic plug-in that automates the generation of metadata (title, description, and keywords) for photos in your catalog using the [PhotoTag.ai API](https://www.phototag.ai). This tool makes it easy to add AI-generated, context-aware metadata to your images, streamlining the process of organizing and optimizing your photo collection.

## Features

- **Automatic Metadata Generation**: Generate **title**, **description**, and **keywords** for your photos automatically with AI.
- **Multi-Language Support**: Generate metadata in multiple languages, including English, Spanish, French, and more.
- **Custom Keyword Options**: Customize the number of keywords, required and excluded keywords, and context-specific keywords for more accurate results.
- **Batch Processing**: Process multiple photos in a single run, with progress tracking.
- **Integration with Lightroom**: The generated metadata is written directly to Lightroom's native fields (title, caption, and keywords).

## Installation

1. **Download the Plugin**: Clone or download this repository to your local machine.
2. **Add the Plugin to Lightroom**:
   - Open Lightroom Classic.
   - Go to `File` > `Plug-in Manager`.
   - Click `Add`, then navigate to the folder where you saved the plug-in, and click `Add Plug-in`.
3. **Configure API Settings**:
   - In the Lightroom Plug-in Manager, configure your **PhotoTag.ai API token**.
   - Customize your settings, such as language preferences, keyword limits, and context, to suit your needs.

## How to Use

1. **Select Photos**: Select the photos you want to generate metadata for in Lightroom.
2. **Run the Plugin**: Go to `Library` > `Plug-in Extras` > `Generate Metadata for Selected Photos`.
3. **Progress Bar**: The plug-in will display a progress bar while it processes the selected photos.
4. **Review and Edit Metadata**: After processing, the generated title, description, and keywords will be added to the selected photos. You can review or further edit the metadata as needed.

## Configuration

You can customize the following settings via the Lightroom Plug-in Manager:

- **API Token**: Your PhotoTag.ai API key.
- **Language**: Choose the language for generated metadata (e.g., English, Spanish, French, etc.).
- **Maximum Keywords**: Set the maximum number of keywords to be generated for each photo.
- **Required Keywords**: Specify keywords that must be included in the generated metadata.
- **Excluded Keywords**: Define keywords that should not appear in the metadata.
- **Custom Context**: Provide additional context to improve the accuracy of metadata generation.
- **Maximum/Minimum Characters**: Set character limits for titles and descriptions.

## Requirements

- Adobe Lightroom Classic (version 5.0 or higher)
- A PhotoTag.ai API key (available from [PhotoTag.ai](https://www.phototag.ai/api))
- An active internet connection (for PhotoTag.ai API)
