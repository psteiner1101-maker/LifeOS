import { z } from "zod";

export const signUpSchema = z.object({
  email: z.email(),
  password: z.string().min(12, "Password must be at least 12 characters."),
});

export const signInSchema = z.object({
  email: z.email(),
  password: z.string().min(1, "Password is required."),
});

export const forgotPasswordSchema = z.object({
  email: z.email(),
});

export const resetPasswordSchema = z
  .object({
    password: z.string().min(12, "Password must be at least 12 characters."),
    confirmPassword: z.string().min(12, "Password must be at least 12 characters."),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords must match.",
    path: ["confirmPassword"],
  });
