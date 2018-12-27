# go-error-handling-logging-practice

Golang application (not library)'s error handling and logging practice

## The specification Version

The specification version is **v0.1.0-0** .

## Overview

Error handling and logging is one of the most common task.
This is one of the practice about the problem.

## Premise

* Use [logrus](https://github.com/sirupsen/logrus) and [go-errlog](https://github.com/suzuki-shunsuke/go-errlog)

logrus is a very popular structured logging library.
go-errlog is a library to let error have structured data and multiple error messages and log the error with logrus easily.

The usecase we suppose is to output logs as JSON format and forward them to Elasticsearch with fluentd.

## Log Level

We don't know the standard log level specification, but we use some log levels according to the following rules.

level | description
--- | ---
debug | Basically we don't use this. We use temporarily this for debugging. If we want to output the log always, use the log level `info`.
info | Not error log. We use mainly this to log event's start and end.
warn | Not system but user error. We don't alert as soon as this log but if too many logs are outputed it may mean bugs or bad UI so we alert.
error | System error. The threadhold is different per application, but we alert.
fatal | Fatal error and it is difficult to continue running the application. Basically it is used only at application's initializaiton proccess such as invalid configuration. We shouldn't use `logrus.Fatal` to omit the error handling.

## Delegate the logging of error to the caller as much as possible

```go
if f, err := os.Open("foo.txt"); err != nil {
	// Instead of logging, return error
	// logrus.Error(err)
	return errlog.Wrap(err, logrus.Fields{"file_name": "foo.txt"}, "failed to open a file")
}
```

## Return error related information to caller

To delegate the logging of error to the caller, the function should return error related information to the caller.
Otherwise, the log would lack necessary information.

We think there are two types of such information and we say them as `message` and `structured data`.

1. message: human readable text which describe error cause.
2. structured data:

For example, in case it is failed to create the user whose name is "foo",

1. messages are `username is already used`, `invalid username`, `failed to create a user`
2. structured data are `{"username": "foo"}`

We don't include structured data into messages with format verbs because

* we log structured data themselves
* it makes codes complicated meaninglessly 
* it makes difficult to search or aggregate logs.

We use go-errlog instead of [pkg/errors](https://github.com/pkg/errors) because pkg/errors doesn't support `structured data`.

go-errlog supports structured data and multiple messages.

```go
errlog.Wrap(err, logrus.Fields{"filename": filename}, "failed to open a file", "failed to create a user")
```

## Which data function should includes to error

The function should include all data which the function has into the error, so the caller doesn't have to include the function's arguments and the message which means the function failed into the error.

Good example

```go
func createUser(name string, age int) error {
	if err := checkName(name); err != nil {
		return errlog.Wrap(err, logrus.Fields{"age": age}, "failed to create a user")
	}
}
```

Bad example

```go
func createUser(name string, age int) error {
	if err := checkName(name); err != nil {
		return errlog.Wrap(err, logrus.Fields{"name": name, "age": age}, "failed to check a name", "failed to create a user")
	}
}
```

But if the function is standard library or third party library, the caller should include such data
because the function basically doesn't use go-errlog.

And also if the function is Go's interface, the caller should include such data.
We shouldn't expect the function includes data which the caller knows into the error.
When we implement the function which is expected to be called as the interface or interface's method, we should include only data which the caller can't know into the error.

## The order of messages

This is a rule about usage of `go-errlog`.

When we pass multiple messages to `errlog.Wrap` as arguments, we should order them time series.

```go
return errlog.Wrap(err, logrus.Fields{"name": name, "age": age}, "failed to check a name", "failed to create a user")
```

In the above example, After "failed to check a name" occurs, "failed to create a user" occurs.

## License

[MIT](LICENSE)
