import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test("home page renders the foundation placeholder", async ({ page }) => {
  await page.goto("/");
  await expect(
    page.getByText("LifeOS project foundation is set up."),
  ).toBeVisible();
});

test("home page has no automatically detectable accessibility violations", async ({
  page,
}) => {
  await page.goto("/");
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
