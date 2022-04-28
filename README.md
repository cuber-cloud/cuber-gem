<a href="https://cuber.cloud"><img src="https://cuber.cloud/assets/images/logo.svg" alt="Cuber" height="80" width="80"></a>
  
# CUBER

[![Gem Version](https://badge.fury.io/rb/cuber.svg)](https://badge.fury.io/rb/cuber)

Deploy your apps on Kubernetes easily.

## What is Cuber?

Cuber is an automation tool (written in Ruby) that can package and deploy your apps (written in any language and framework) on Kubernetes.

Unlike other tools that add more options and more complexity to Kubernetes, Cuber is made to simplify and reduce the complexity.

Kubernetes is up to 80% cheaper compared to PaaS like Heroku and you can choose between different cloud providers (no lock-in).
It is also reliable and it can scale enterprise applications at any size.
The only downside is that it's difficult to master...
Cuber makes Kubernetes simple!
In this way you have the simplicity of a PaaS, at the cost of bare infrastructure and without the additional cost of a DevOp team.

[Read more](https://cuber.cloud/docs/overview)

## Installation

First you need to [install the prerequisites](https://cuber.cloud/docs/installation): `ruby`, `git`, `docker`, `pack`, `kubectl`.

Then install Cuber:

```
$ gem install cuber
```

## Quickstart

Open your application folder and create a `Cuberfile`, for example:

```ruby
# Give a name to your app
app 'myapp'

# Get the code from this Git repository
repo '.'

# Build the Docker image automatically (or provide a Dockerfile)
buildpacks 'heroku/buildpacks:20'

# Publish the Docker image in a registry
image 'username/myapp'

# Connect to this Kubernetes cluster
kubeconfig 'path/to/kubeconfig.yml'

# Run and scale any command on Kubernetes
proc :web, 'your web server command'
```

You can also see [a more complete example](https://cuber.cloud/docs/quickstart).

Then in your terminal:

```
$ cuber deploy
```

Finally you can also monitor the status of your application:

```
$ cuber info
```

Check out the [Cuberfile configuration](https://cuber.cloud/docs/cuberfile) and the [Cuber CLI commands](https://cuber.cloud/docs/cli) for more information.

## License

Cuber is released under a source-available license:
[Standard Source Available License (SSAL)](https://github.com/collimarco/Standard-Source-Available-License)

Cuber is completely free up to 5 procs per app. If you are a large customer, and you need more procs, please [purchase a license](https://cuber.cloud/buy) (it also includes dedicated support).

Contributions are welcome: you can fork this project on GitHub and submit a pull request. If you submit a change / fix, we can use it without restrictions and you transfer the copyright of your contribution to Cuber.

## Learn more

You can find more information and documentation on [cuber.cloud →](https://cuber.cloud)

