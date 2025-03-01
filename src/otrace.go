package main

import (
	"context"
	"errors"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploggrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/exporters/stdout/stdoutlog"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/log/global"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/log"
	"go.opentelemetry.io/otel/sdk/trace"
)

func setupOTelSDK(ctx context.Context) (shutdown func(context.Context) error, err error) {
	var shutdownFuncs []func(context.Context) error

	// shutdown calls cleanup functions registered via shutdownFuncs.
	// The errors from the calls are joined.
	// Each registered cleanup will be invoked once.
	shutdown = func(ctx context.Context) error {
		var err error
		for _, fn := range shutdownFuncs {
			err = errors.Join(err, fn(ctx))
		}
		shutdownFuncs = nil
		return err
	}

	// handleErr calls shutdown for cleanup and makes sure that all errors are returned.
	handleErr := func(inErr error) {
		err = errors.Join(inErr, shutdown(ctx))
	}

	// Set up propagator.
	prop := newPropagator()
	otel.SetTextMapPropagator(prop)

	// Set up trace provider.
	tracerProvider, err := newTracerProvider()
	if err != nil {
		handleErr(err)
		return
	}
	shutdownFuncs = append(shutdownFuncs, tracerProvider.Shutdown)
	otel.SetTracerProvider(tracerProvider)

	// azure application inghts otel telemetry does not support meter provider
	/*
		// Set up meter provider.
		meterProvider, err := newMeterProvider()
		if err != nil {
			handleErr(err)
			return
		}
		shutdownFuncs = append(shutdownFuncs, meterProvider.Shutdown)
		otel.SetMeterProvider(meterProvider)
	*/

	// Set up logger provider.
	loggerProvider, err := newLoggerProvider(ctx)
	if err != nil {
		handleErr(err)
		return
	}
	shutdownFuncs = append(shutdownFuncs, loggerProvider.Shutdown)
	global.SetLoggerProvider(loggerProvider)

	return
}

func newPropagator() propagation.TextMapPropagator {
	return propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	)
}

func newLoggerProvider(ctx context.Context) (*log.LoggerProvider, error) {

	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	var logExporter log.Exporter
	var err error

	if endpoint == "" {
		logExporter, err = stdoutlog.New()
		if err != nil {
			return nil, err
		}
	} else {
		logExporter, err = otlploggrpc.New(ctx)
		if err != nil {
			return nil, err
		}

	}

	loggerProvider := log.NewLoggerProvider(log.WithProcessor(log.NewBatchProcessor(logExporter)))
	return loggerProvider, nil
}

func newTracerProvider() (*trace.TracerProvider, error) {

	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	var traceExporter trace.SpanExporter
	var err error

	if endpoint == "" {
		traceExporter, err = stdouttrace.New(
			stdouttrace.WithPrettyPrint())
		if err != nil {
			return nil, err
		}
	} else {
		traceExporter, err = otlptracegrpc.New(context.Background())
		if err != nil {
			return nil, err
		}
	}

	// Default is 5s. Set to 1s for demonstrative purposes.
	tracerProvider := trace.NewTracerProvider(
		trace.WithBatcher(traceExporter,
			trace.WithBatchTimeout(time.Second)),
	)
	return tracerProvider, nil
}
