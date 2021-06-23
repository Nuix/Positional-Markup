Positional-Markup
==========

![9.2](https://img.shields.io/badge/Script%20Tested%20in%20Nuix-9.2-green.svg)

View the GitHub project [here](https://github.com/Nuix/Positional-Markup) or download the latest release [here](https://github.com/Nuix/Positional-Markup/releases).

# Overview

Apply redactions to identically sized items and validate of matching text to ensure the identity matches before applying the markup. This is great for form based data where the position of the form is more efficient way of applying a redaction.

# Getting Started

## Setup

Begin by downloading the latest release of this code.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

### Configuration

#### Step 1 Start by defining two markups:

A 'Pilot' Markup and an 'Applied' Markup.

The Pilot Markup is used to define on items the highlights to represent the areas of text that must match. If these highlights match another items text in those areas the Redaction area's are copied over onto the Applied Markup.

The two markups could be the same however it is recommended to test with different so that the differences can be noted.

#### Step 2 Determine items to apply this pilot

One way you could do this is search for known terms that are found on these documents (e.g. first name or phone number). After you have these items select them all

#### Step 3 Run the script

Scripts Menu -> Positional Markup

#### Step 4 Wait

A progress dialog will show on screen to represent the progress being made against the selected items.

#### Step 5 Evaluate remaining

The items that have FAILED will be shown in a new tab. This is so that further pilots can be generated, then select all and run the script again until no items remain.





# License

```
Copyright 2020 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
