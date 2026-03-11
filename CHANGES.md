# CHANGES

This document tracks the new programs' deviations from the old one.

## Input files

1. The new program supports up to 6 wanted classes.
2. The new program now expects input in UTF-8 encoding. An option to set output
encoding should be available in all major text processors.
3. Given input files in UTF-8 encoding, the new program handles all common
special characters like smart quotes.

## Splitting and Dropping

1. Now splitting and dropping can be performed interchangeably.
2. Splitting controls are only available when clicking on the resulting class
row, but not others.

## Coordinators

1. Coordinator controls are only available when clicking on the course titles,
but not others.
2. The two buttons for setting coordinators are now "Set C and CC" and "Set CC1
and CC2".
  a. To set main and co coordinators, select a person, click "Set C and CC",
  select another, and then click "Set C and CC".

  * Clicking the "Set C and CC" button a second time now clears any
    previous coordinator selection before starting a new assignment, allowing
    both C and CC to be reset. Previously the old main coordinator remained
    highlighted which meant only the co-coordinator could be changed.
  * The same clearing behavior is now performed when re-entering the
    "Set CC1 and CC2" mode so that both co-coordinators can be picked anew.
  * While coordinators are being shown, tapping a highlighted name will now
    delete the entire coordinator assignment for the course.  This provides a
    quick way to remove C/CC without switching back into selection mode.
  b. To set two co coordinators, select a person, click "Set CC1 and CC2",
  select another, and then click "Set CC1 and CC2".

## Saving and Loading

1. Intermediate states are now stored in a readable and editable file format.

## Exporting

1. MailMerge files now have 9 extra columns per line to support members wanting
more than 3 classes.

