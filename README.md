![Atlasboard](https://bitbucket.org/atlassian/atlasboard/raw/master/screenshots/wallboard8x6.png)

[![Build Status](https://drone.io/bitbucket.org/atlassian/atlasboard/status.png)](https://drone.io/bitbucket.org/atlassian/atlasboard/latest)

Atlasboard is a dashboard framework written in nodejs. Check out the [website](http://atlasboard.bitbucket.org).


# Installation

``npm install -g atlasboard``


# Creating your first wallboard

``atlasboard new mywallboard``


# Importing your first package

You will probably want to reuse other people's dashboards, widgets and jobs. To do so, you'll need to import a "package", which is just a [git submodule](http://git-scm.com/docs/git-submodule).

The [Atlassian package](https://bitbucket.org/atlassian/atlasboard-atlassian-package) is a good place to start. If you haven't already, initialise a git repository for your new wallboard, and then type:

    git init
    git submodule add https://bitbucket.org/atlassian/atlasboard-atlassian-package packages/atlassian


## Packages and resources

### Atlassian contributions

- [Atlassian Atlasboard package](https://bitbucket.org/atlassian/atlasboard-atlassian-package)

### Community contributions

- [atlasboard-red6-package](https://github.com/red6/atlasboard-red6-package)
- [Stuart Jones's package](http://stuartjones.me/web-development-team-dashboard/)
- [dcopestake's atlasboard-aws package](https://www.npmjs.com/package/atlasboard-aws)
- [arhs-atlasboard](https://www.npmjs.com/package/arhs-atlasboard)

If you'd like your packages to be included here, please send us a link.


# Documentation

## Architecture

![Build Status](https://bitbucket.org/repo/48jGE4/images/3890828144-atlasboard-structure.png)

## Components

#### Dashboards

To create your first dashboard, type the following command:

```
atlasboard generate dashboard mydashboard
```

This will generate a default dashboard using [this template](https://bitbucket.org/atlassian/atlasboard/raw/master/samples/dashboard?at=master).


##### Dashboard descriptor structure:

* `enabled` enables/displays the dashboard. This is a quick way to hide your dashboard without having to delete it.

* `title` dashboard title (optional). Most of the time you will not need this.

* `layout`

    * `gridSize` grid size is customizable ( `"gridSize" : { "columns" : 8, "rows" : 6 } `)

    * `customJs` the names of any extra JavaScript libraries, located in `assets/javascripts`, that you'd like included. *(warning: this could be moved out of the layout key in future releases)*.

    * `widgets` an array of objects detailing each widget to be displayed on the dashboard. Each `widgets` object has the following attributes:

        * `enabled` true/false

        * `row` value from 1 to maxRows.

        * `col` value from 1 to maxColumns.

        * `width` number of columns this widget will occupy

        * `height` number of rows this widget will occupy

        * `widget` widget name. If you want to refer to a widget inside an specific package, use the namespace `<package>#<widgetname>` syntax (e.g. ``atlasboard#quotes``).

        * `job` Job to be executed. The same namespace syntax applies to specifying jobs.

        * `config` The config key that will be use for this dashboard item.

* `config` a config object for this dashboard, containing a key-value container for job configuration. 


##### Example dashboard config file

```
{
  "enabled": true,
  "layout": {           
    "title": false,
    "gridSize" : { "columns" : 6, "rows" : 4 },
    "customJS" : [],
    "widgets" : [
      {
        "row" : 1, "col" : 1, 
        "width" : 2, "height" : 3,
        "widget" : "quotes", "job" : "quotes-famous", "config" : "quotes"
      }
    ]
  },

  "config" : {
    "quotes" : {
      "numberQuotes" : 10
    }
  }
}
```

##### Using the common dashboard config file

If you want to share the same configuration for more than one dashboard, place it inside `/config/dashboard_common.json` so that you don´t have to repeat it. Atlasboard will merge the configuration keys found in this file with the current dashboard configuration.

#### Jobs

Jobs are run in the background by the scheduler. Their purpose is to send data to the client-side widgets. You can generate one in the default package by typing:

```
atlasboard generate job myjob
```

This will generate a job using [this template](https://bitbucket.org/atlassian/atlasboard/raw/master/samples/job?at=master).

A very simple job could look like this:

```
module.exports = function(config, dependencies, job_callback) {
    var text = "Hello World!";
    // first parameter is error (if any). Second parameter is the job result (if success)
    // you can use the following dependencies:
    // - dependencies.request : request module (https://github.com/mikeal/request)
    // - dependencies.logger : logger interface

   job_callback(null, {title: config.widgetTitle, text: text});
};
```

If you want to do something more interesting, like scraping data for example:

```
var $ = require('cheerio');

module.exports = function(config, dependencies, job_callback) {
	var logger = dependencies.logger;
	dependencies.easyRequest.HTML('http://myprivatewebsite.com', function(err, html) {
		var result = [];
		if (err) {
			logger.error('there was an error running my job, let\'s log it!);
			// send error message to the widget so it can handle it
			job_callback(err);
		} else {
			var $page = $(html);
			$page.find('table tr').each(function(index, element) {
				result.push($(element).find('td:nth-child(1)'));
			});
			// this is being sent to the widget through the socket channel
			job_callback(null, { data: result }); 
		}
	});
};
```

As you may notice, Atlasboards exposes a few handy dependencies. Check [their source](https://bitbucket.org/atlassian/atlasboard/raw/master/lib/job-dependencies/?at=master).


#### Widgets

Widgets run in the client-side. To create one:

```
atlasboard generate widget mywidget
```

This will generate a widget using [this template](https://bitbucket.org/atlassian/atlasboard/raw/master/samples/widget?at=master).


These are the files created for you in your default package:

##### mywidget.html

```
<h2>mywidget</h2>
<div class="content"></div>
```


##### mywidget.css

```
.content {
    font-size: 35px;
    color: #454545;
    font-weight: bold;
    text-align: center;
}
```

##### mywidget.js

```
widget = {
    //runs when we receive data from the job
    onData: function(el, data) {

        //The parameters our job passed through are in the data object
        //el is our widget element, so our actions should all be relative to that
        if (data.title) {
            $('h2', el).text(data.title);
        }

        $('.content', el).html(data.text);
    }
};
```

## Command line filters

To run one particular job only:

```
atlasboard start --job thejobIAmWorkingOnRegEx
```

Or one particular dashboard:

```
atlasboard start --dashboard theDashboardIAmWorkingOnRegex
```

This is specially useful during development so you only bring up the components you need.

## Log visualizer

If you enable real-time logging in ``yourwallboard/config/atlasboard.json``, you will be able to access logs through a socket.io connection:

```
{
  "live-logging" : {
    "enabled": true
  }
}
```

[Log viewer](https://bitbucket.org/atlassian/atlasboard/raw/master/atlasboard-log-viewer.png)

## Credentials

[Check the wiki for more info about the globalAuth.json file](https://bitbucket.org/atlassian/atlasboard/wiki/Atlasboard%20Authentication)

You can also use environment variables in your globalAuth.json:

```
{
  "hipchat": {
    "token": "${HIPCHAT_TOKEN}"
  },
  "stash": {
    "username": "${STASH_USER}",
    "password": "${STASH_PASS}"
  },
  "bitbucket.org": {
    "username": "${BITBUCKET_USER}",
    "password": "${BITBUCKET_PASS}"
  },
  "graphite": {
    "username": "${GRAPHITE_USER}",
    "password": "${GRAPHITE_PASS}"
  }
}
```

in your shell:

```
export HIPCHAT_TOKEN='yourpassword' 
```


# Contributing to Atlasboard

- Raise bug reports
- Fix anything on https://bitbucket.org/atlassian/atlasboard/issues?status=new&status=open

# Roadmap

Planned for future releases:

- Extension points. Packages would be able to plug routes. Middleware. Client-side plugins.
- Theme support.
- Edit dashboard configuration live.
- More and better widgets. Make easier to introduce front-end dependencies in packages. Examples of widgets written using React.

# Release history

## 1.0.0

- Bump to Express 4
- Stylus support in Widgets
- Atlaboard default color palette in stylus (which widgets can use)
 
## 0.13.0

- Fix issue #98: Expose pushUpdate functions to jobs to push updates to the widget independently of the scheduler interval cycle
- Internal scheduler refactoring. Remove singletons

## 0.12.0

- Added a check to change the NPM command executed based on platform

## 0.11.0

- Remove console-helper
- Allow custom templates to be defined in the local wallboard
- Add bower to manage Atlasboard core front-end dependencies
- Bump jQuery to 2.x. IE8 not supported anymore (if it ever was)
- Unique events for widgets, even if they have the same combination of job, widget name and configuration.
- Use "disabled" text instead of default error icon when widget is disabled
- Send the AtlasBoard version in the User-Agent (request job dependency)
- Fix deprecation warnings in use of Express
- Warning when multiple callback execution detected in a job

## 0.10.0

- Enable the cookie jar for request
- Introduce install command and --noinstall option to start command
- Add HipChat roomInfo endpoint and support for api v2
- Upgrade request to ^2.53.0
- Add support for expanding environment variables in globalAuth.json
- Send errors to the client immediately (ignoring retry settings) on the first run
- Always send error events to the client
- Don't use absolute links / proxy support

## 0.9.0

- Fix warning icon image
- Use spin.js instead of an image spinner
- Bump gridster to 0.5.6
- Bump rickshaw to 1.5
- Add an experimental confluence library to assist in fetching pages using Content API
- Make sure config is never undefined
- Fixing schedulers so job execution doesn't overlap if it takes too long

## 0.8.0

- Improve project and job scaffolding
- Add unit test to new job template
- Bump up a bunch of dependencies (it was about time!)
- Improve socket.io reconnect
- Add new shinny 8x6 grid size screenshot

## 0.7.0

- Allow configurable (per dashboard) grid size (issue #64)
- Bump up cheerio to 0.13.1
- Bump up grister to 0.5.1
- Avoid widget title wrapping
- related to issue #64
- Fix package.json "bin" attribute relative path.

## 0.6.0

- FIX: Issue #62. Properly namespace widget CSS by working with AST rules
- Issue #50 and #60. Make easier developing new jobs by adding filters to atlasboard start
- Refactor commands
- Added more unit tests
- Install only production dependencies on atlasboard start
- Ensure that we return pg clients to the connection pool
- Other minor fixes

## 0.5.6

- Added easyRequest for easier querying HTTP resources.

## 0.5.5

- Upping rickshaw graphics

## 0.5.4

- workaround was clearing the cache)

## 0.5.3

- FIX: Issue #53 Two versions of colors on disk throw.
- Some refactoring and some of the pending code style changes.
- Add build status using drone.io
- package order resolution in widgets
- FIX: Function.prototype.apply expect array in second arguments

## 0.5.2

- Add moment as job dependency
- Add underscore job dependency
- Add async dependency for jobs
- Use non-minified versions for easy browser debugging
- Add/remove widget-level loading class for better styling context

## 0.5.1

- Issue #42: fixed small regression for reconnects

## 0.5.0

- Move packages from packages to samples/project/packages to avoid users build the dashboard in an atlasboard clone.
- Clearer error message when job not found
- Add {"start": "atlasboard start"} to project scaffold package.json
- Error 500 rendering stylesheets/application.css
- Issue #42: Nicer handling of error messages in the UI
- Add rickshaw library to atlasboard core
- Add postreSQL job dependency
- Move third party assets to a separate third-party folder
- Add storage dependency. Refactor dependency injection.
- Issue #28 Add support for credentials file path

## 0.4.0

- Change widget naming to not include widget id anymore
- Added default config file so the custom one gets extended from this one.
- Fix default dashboard so it has the necessary widgets to fill the whole screen.
- Reorganize tests.
- Use logger to wrap the error when a dashboard has the wrong format.
- Make job manager error proof in case config file doesn't exists. If config file exists and it is invalid it should throw error.
- Added hipchat integration. New hipchat dependency.
- Allow fetching resources from widget folder.
- Display error and exit if http server port is in use
- Fix problem when displaying error with prevent the widget from displaying data again.
- A dashboard name must match /^[a-zA-Z0-9_-]*$/ to be valid.
- Other minor fixes.

## 0.3.1

- FIX: Require node 0.8 or higher in package.json

## 0.3.0

- Real-time logging visualization!.
- Issue #13: "generate dashboard" generates files in a sub-folder.
- Removed sample dashboard from atlasboard.
- Ability to disable dashboards by setting enabled:false in dashboard config file.
- Job task is executed in the context of the job object, so we can manage state across executions.
- Error handling and logging on jobs
- Prevent XSS in log viewer.
- Extra test coverage
- Disable logging by default through the config file
- Use connect-assets to serve css (and parse stylus)
- Enable serving of custom images from dashboards
- Improve startup banner

## 0.2.0

- can now resize browser and scale AtlasBoard.
- use connect-asset for common assets, since we are fetching now widget assets on demand.

## 0.1.1

- new atlasboard "list" command.
- handle errors on child process when executing "npm install".
- use minified versions of javascript libraries.

## 0.1.0

- first release after some important changes in the core architecture.
