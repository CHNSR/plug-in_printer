#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "flutter_printer01_plugin.h"

namespace flutter_printer_01 {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(FlutterPrinter01Plugin, Initialization) {
  FlutterPrinter01Plugin plugin;
  EXPECT_TRUE(true);
}

}  // namespace test
}  // namespace flutter_printer_01
