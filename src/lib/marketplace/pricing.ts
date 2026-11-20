import { z } from "zod";

export const listingPriceSchema = z.object({
  priceAmount: z.number().finite().nonnegative().max(9999999999.99).nullable(),
  currency: z.enum(["INR", "USD"]),
  priceType: z.enum(["fixed", "negotiable"])
}).superRefine((value, context) => {
  if (value.priceAmount === null && value.priceType !== "fixed") {
    context.addIssue({ code: "custom", path: ["priceAmount"], message: "A negotiable listing must include an asking price." });
  }
});

export type ListingPrice = z.infer<typeof listingPriceSchema>;

export function formatListingPrice(price: ListingPrice, locale = "en-IN") {
  if (price.priceAmount === null) return "Free";
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency: price.currency,
    maximumFractionDigits: 2
  }).format(price.priceAmount);
}
