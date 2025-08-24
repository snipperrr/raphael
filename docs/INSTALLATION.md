# Installation Guide

Follow these steps to install the RaphaelEA on your MetaTrader 5 terminal.

## 1. Download the Source Code

Download the latest version of RaphaelEA from the [official repository](https://github.com/RaphaelEA/RaphaelEA).

## 2. Locate Your MT5 Data Folder

In your MetaTrader 5 terminal, go to `File > Open Data Folder`.

## 3. Copy the EA Files

- Copy the `src` folder into your `MQL5/Experts/` directory.
- Copy the `presets` folder into your `MQL5/Presets/` directory.
- Copy the `scripts` folder into your `MQL5/Scripts/` directory.

## 4. Compile the EA

- In MetaTrader 5, open the `MetaEditor` by pressing `F4`.
- In the `Navigator` window, find `RaphaelEA.mq5` under `Experts/src/`.
- Double-click to open the file.
- Click the `Compile` button (or press `F7`).

## 5. Attach to Chart

- In the `Navigator` window of the main MT5 terminal, right-click on `Expert Advisors` and select `Refresh`.
- Drag `RaphaelEA` from the `Expert Advisors` list onto a chart.

## 6. Configure Parameters

- In the EA's input settings window, you can load a preset for your symbol by clicking `Load` and selecting the appropriate `.set` file from the `presets` folder.
- Adjust any other parameters as needed.

## 7. Enable Automated Trading

- Click the `Algo Trading` button in the main toolbar to enable automated trading.
