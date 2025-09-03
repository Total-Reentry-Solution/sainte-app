# Sainte iOS, Android, and Web

A Flutter project.

## Getting Started

This project is a Flutter application for Sainte mobile and web app.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI and Monitoring

- GitHub Actions run separate Android and iOS pipelines to execute unit and UI tests.
- A simple `FeatureFlags` utility enables phased rollouts so early adopters can try new features.
- `MonitoringService` provides hooks for analytics and crash reporting to ensure parity with the original Flutter release.
