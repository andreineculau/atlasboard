![Atlasboard](https://bitbucket.org/atlassian/atlasboard/raw/master/screenshots/wallboard8x6.png)

##Build status##

[![Build Status](https://drone.io/bitbucket.org/atlassian/atlasboard/status.png)](https://drone.io/bitbucket.org/atlassian/atlasboard/latest)

##Installation##

`npm install -g atlasboard`


##Creating your first wallboard##

After installing Atlasboard as a global module, you may want to do this:

`atlasboard new mywallboard`


to generate your wallboard.


##Importing your first package##

You probably want to reuse the dashboards, widgets and jobs that people have already created.

The [Atlassian package](https://bitbucket.org/atlassian/atlasboard-atlassian-package) is a good start. Atlasboard packages are installed as submodules. You need to initialise a git repository first. Just type:

    git init
    git submodule add https://bitbucket.org/atlassian/atlasboard-atlassian-package packages/atlassian

Don't forget to setup your credentials (globalAuth.json file)!

## Documentation

[Check out the wiki](https://bitbucket.org/atlassian/atlasboard/wiki/Home)

## More information 

Check out the [Atlasboard website](http://atlasboard.bitbucket.org).
