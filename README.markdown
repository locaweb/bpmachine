bpmachine
=========

bpmachine is a ruby gem created to act as a state machine for
the application in order to control each status of whole process.

It was made to work with `activerecord` but it will work with any
class that implements the `save!` method.

How to use it
-------------

Add it to your Gemfile

    gem "bpmachine"

Include the `ProcessSpecification` module in your class:

    class MyClass
      include ProcessSpecification
    end

Define your process

    include ProcessSpecification
    process :of => :anything do
      transition :some_event, :from => :initial, :to => :final
    end

The gem will look for a `AnythingSteps` in the `app/steps` directory
and run the `some_event` method, changing the object status of
`MyClass` from `:initial` to `:final`.


Contributors
------------

* [Fabio Kung](http://github.com/fabiokung)
* [Willian Molinari (a.k.a PotHix)](http://pothix.com)


Copyright
---------

Copyright (c) 2016 Locaweb. See LICENSE for details.
