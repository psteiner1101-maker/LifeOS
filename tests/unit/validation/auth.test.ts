import { describe, expect, it } from "vitest";
import {
  forgotPasswordSchema,
  resetPasswordSchema,
  signInSchema,
  signUpSchema,
} from "@/lib/validation/auth";

describe("signUpSchema", () => {
  it("accepts a valid email and a password of at least 12 characters", () => {
    const result = signUpSchema.safeParse({
      email: "user@example.com",
      password: "correct-horse-battery",
    });
    expect(result.success).toBe(true);
  });

  it("rejects an invalid email", () => {
    const result = signUpSchema.safeParse({
      email: "not-an-email",
      password: "correct-horse-battery",
    });
    expect(result.success).toBe(false);
  });

  it("rejects a password shorter than 12 characters", () => {
    const result = signUpSchema.safeParse({
      email: "user@example.com",
      password: "short123456",
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty email", () => {
    const result = signUpSchema.safeParse({
      email: "",
      password: "correct-horse-battery",
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty password", () => {
    const result = signUpSchema.safeParse({
      email: "user@example.com",
      password: "",
    });
    expect(result.success).toBe(false);
  });
});

describe("signInSchema", () => {
  it("accepts a valid email and any non-empty password", () => {
    const result = signInSchema.safeParse({
      email: "user@example.com",
      password: "short",
    });
    expect(result.success).toBe(true);
  });

  it("rejects an invalid email", () => {
    const result = signInSchema.safeParse({
      email: "not-an-email",
      password: "short",
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty password", () => {
    const result = signInSchema.safeParse({
      email: "user@example.com",
      password: "",
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty email", () => {
    const result = signInSchema.safeParse({
      email: "",
      password: "short",
    });
    expect(result.success).toBe(false);
  });
});

describe("forgotPasswordSchema", () => {
  it("accepts a valid email", () => {
    const result = forgotPasswordSchema.safeParse({
      email: "user@example.com",
    });
    expect(result.success).toBe(true);
  });

  it("rejects an invalid email", () => {
    const result = forgotPasswordSchema.safeParse({
      email: "not-an-email",
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty email", () => {
    const result = forgotPasswordSchema.safeParse({
      email: "",
    });
    expect(result.success).toBe(false);
  });
});

describe("resetPasswordSchema", () => {
  it("accepts matching passwords of at least 12 characters", () => {
    const result = resetPasswordSchema.safeParse({
      password: "correct-horse-battery",
      confirmPassword: "correct-horse-battery",
    });
    expect(result.success).toBe(true);
  });

  it("rejects mismatched passwords", () => {
    const result = resetPasswordSchema.safeParse({
      password: "correct-horse-battery",
      confirmPassword: "different-horse-battery",
    });
    expect(result.success).toBe(false);
  });

  it("rejects a password shorter than 12 characters", () => {
    const result = resetPasswordSchema.safeParse({
      password: "short123456",
      confirmPassword: "short123456",
    });
    expect(result.success).toBe(false);
  });

  it("rejects an empty password", () => {
    const result = resetPasswordSchema.safeParse({
      password: "",
      confirmPassword: "",
    });
    expect(result.success).toBe(false);
  });
});
