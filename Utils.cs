using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

public class Utils : Node {
	public static Node GetSingleton(Node node, String name) {
		return node.GetNode("/root/" + name);
	}
	
	public static void print<A>(A a) {
		GD.Print(a);
	}
	public static void print<A, B>(A a, B b) {
		GD.Print(a, b);
	}
	public static void print<A, B, C>(A a, B b, C c) {
		GD.Print(a, b, c);
	}
	public static void print<A, B, C, D>(A a, B b, C c, D d) {
		GD.Print(a, b, c, d);
	}
	public static void print<A, B, C, D, E>(A a, B b, C c, D d, E e) {
		GD.Print(a, b, c, d, e);
	}
	
	public static void sprint<A>(A a) {
		GD.Print(a);
	}
	public static void sprint<A, B>(A a, B b) {
		GD.Print(a, " | ", b);
	}
	public static void sprint<A, B, C>(A a, B b, C c) {
		GD.Print(a, " | ", b, " | ", c);
	}
	public static void sprint<A, B, C, D>(A a, B b, C c, D d) {
		GD.Print(a, " | ", b, " | ", c, " | ", d);
	}
	public static void sprint<A, B, C, D, E>(A a, B b, C c, D d, E e) {
		GD.Print(a, " | ", b, " | ", c, " | ", d, " | ", e);
	}
	
	public static void assert(bool condition, String message = "(No message provided)") {
		if (!condition) AssertionFailed(message);
	}
	
	private static void AssertionFailed(String message) {
		message = "Assertion failed: " + message;
		GD.Print("");
		GD.PrintErr(message + "\nStack trace:");
		GD.PrintStack();
		GD.Print("");
		throw new Exception(message);
	}
	
	public static void TriggerGC() {
		GC.Collect();
	}
	
	public static bool CompareV<T>(Vector2 vector, T x, T y) {
		return vector.x == (float)Convert.ChangeType(x, typeof(float)) && vector.y == (float)Convert.ChangeType(y, typeof(float));
	}
	
	// Loads file at [path], parses its contents as JSON, and returns the result.
	public static JSONParseResult LoadJson(String file_path) {
		File f = new File();
		if (!f.FileExists(file_path)) {
			JSONParseResult result = new JSONParseResult();
			result.Error = Error.FileNotFound;
			return result;
		}
		
		Error error = f.Open(file_path, File.ModeFlags.Read);
		if (error != Error.Ok) {
			JSONParseResult result = new JSONParseResult();
			result.Error = error;
			return result;
		}
		
		JSONParseResult ret = JSON.Parse(f.GetAsText());
		f.Close();
		return ret;
	}
	
	public static IEnumerable<T> GetEnumValues<T>() {
		return (T[])Enum.GetValues(typeof(T));
	}
	
	public static List<String> GetEnumValuesString<T>() {
		List<String> ret = new List<String>();
		foreach (T val in (T[])Enum.GetValues(typeof(T))) {
			ret.Add(val.ToString());
		}
		return ret;
	}
	
	public static IEnumerable<MethodInfo> GetMethodsWithAttribute(Type classType, Type attributeType) {
		return classType.GetMethods().Where(methodInfo => methodInfo.GetCustomAttributes(attributeType, true).Length > 0);
	}
}
