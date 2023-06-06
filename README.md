# AI ToDo App

AI todo app usigin Claude to generate todo tasks.

Instructions:
Seems to work well using Chrome (web), so use that. You have to plug in your own API key into the code (Line 415 of home.dart in ai-todolist/lib/screens
/home.dart: const apiKey = 'YOURAPIKEYHERE'; // Replace this with your actual API key). Make sure to put the full key INSIDE the '' (e.g. 'sk-xxx-xxx-xxx-xxx-xxx-xxx').

Misc:
Haven't tested of Android or iOS as of yet. Tested using Windows (desktop), but finnicky when exported. Werks on my machine, the 54edcd49d3a685928e2d902a4b05c414f6546186 commit may be most usable for the Windows version, but comes with CMake errors. The latest works (conceptually), you just need to make sure you've got Flutter and DART to be able to run, alongside being able to build for your platform of choice. Basically, if you actually know what you're doing, you'll be fine. I don't, so I'm just winging it 😎.
