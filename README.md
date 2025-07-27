# E-Commerce-Sales-Intelligence: SKU-Level-Analysis-Growth-Strategy



## Project Background & Overview

This analysis was conducted for a consumer products company operating in the e-commerce/retail space.  Our business goal was to **boost online revenue** and identify high-impact growth opportunities. To do this, we examined daily *sales* and *web-view* data for each product (SKU).  The datasets include **sales\_data** (with SKU, date, revenue, units sold, category, subcategory, and out-of-stock percentage) and **glance\_views** (with SKU, date, page views, and units).  In particular, we focused on SKU-level performance, seasonal patterns (e.g. sales spikes), subcategory growth trends, promotional (sale) events, and conversion drivers (units/views vs. price).

##  Data Structure Overview

The core data model consists of two main tables: **sales\_data** and **glance\_views**.  The **sales\_data** table holds financials and inventory metrics, while **glance\_views** tracks customer traffic and unit conversions per SKU. The key columns are:

* **sales\_data**: `SKU_Name`, `Feed_date`, `Ordered_Revenue`, `Ordered_Units`, `Category`, `SubCategory`, `Rep_OOS` (percentage of out-of-stock views).
* **glance\_views**: `SKU_Name`, `Feed_date`, `Views`, `Units` (page views and units sold).

These tables are related via SKU and date as shown below:

```
+---------------------+             +-------------------+
|     sales_data      |             |    glance_views   |
+---------------------+             +-------------------+
| *SKU_Name*          |◄────────────| *SKU_Name*        |
| *Feed_date*         |             | *Feed_date*       |
| Ordered_Revenue     |             | Views             |
| Ordered_Units       |             | Units             |
| Category            |             +-------------------+
| SubCategory         |
| Rep_OOS             |
+---------------------+
```


## 📊 Executive Summary

* **\~81% of products sold:**  About **80.97%** of SKUs had positive sales in the period (i.e. generated revenue).  Conversely, roughly 19% of SKUs had no sales.  Notably, **116 SKUs** completely stopped selling after July (a sign that those items dropped out of the active catalog or ran out of stock).
* **Sharp one-day spike on July 15, 2019:**  We identified a major sales event on **2019-07-15**, evidenced by a very large spike in both page views and units sold.  This surge was concentrated in certain categories (e.g. computer peripherals and gaming accessories).  Importantly, sales returned to normal immediately afterward – there was **no significant sustained boost or drop** in revenue in the days following the event.
* **Underperforming subcategories:**  Some product lines showed negative growth versus their category.  For example, the *“Tablet Stands and Docks”* subcategory grew only **–16%** over the period (while its parent category grew +19%).  Another outlier was *“Keyboards – DELETED”*, with **–28%** growth (vs. +18% in Computer Peripherals). These lagging subcategories stand out as areas of concern that need review.

## 🔍 Insights Deep Dive

**SKU Sales & Availability:** We aggregated revenue by SKU to see how many products were actively selling.  The analysis confirmed that \~80.97% of SKUs generated some sales.  The remainder (≈19%) never sold any units.  Additionally, 116 SKUs (about 19% of products) sold through July but then **stopped selling in August**.  This suggests those SKUs either ran out of stock or were discontinued.  It may be worthwhile to audit these – for example, are they older or redundant products? From a business perspective, knowing that only \~4/5 of items are active helps focus effort on the top performers.  Low-selling SKUs (and those that dropped off) might be candidates for de-listing or targeted promotions.

| Measure                  | Value  |
| ------------------------ | ------ |
| SKUs with any sales      | 80.97% |
| SKUs with no sales       | 19.03% |
| SKUs stopping after July | 116    |

*Table: Summary of SKU sales activity (81% of SKUs sold; 116 SKUs ceased selling after July).*

**Sale Event and Aftermath:** We summed daily views and units to spot promotional spikes.  One day clearly stood out: **July 15, 2019**, where total site views and units jumped far above the norm.  The table below illustrates the surge (July 15 shows orders of magnitude higher than surrounding days).  This confirms a one-day sale event.  We then compared units sold per day before and after this date using a statistical test (Mann–Whitney).  The result: **no statistically significant increase or decrease** in sales post-event. In other words, the promotion drove a large one-day bump but did not cannibalize or sustain higher sales afterward.  Business implication: flash sales can create short-term volume, but ongoing sales rely on steady demand.

| Feed\_Date     | Total\_Views | Total\_Units |
| -------------- | ------------ | ------------ |
| 2019-07-14     | 50,000       | 8,000        |
| **2019-07-15** | **300,000**  | **50,000**   |
| 2019-07-16     | 45,000       | 7,500        |

*Table: Example daily site totals around July 15, 2019 (bold shows the spike on the sale day).*

**Subcategory Growth Trends:** We analyzed month-over-month revenue to find which subcategories lagged their category.  By computing each subcategory’s average growth and comparing it to its parent category, we identified the worst performers.  The slowest subcategory in **Tablet Accessories** was *“Tablet Stands & Docks”*, which saw an average decline of **–16%** over the May–Aug period (while its category grew +19%).  Similarly, in **Computer Peripherals**, *“Keyboards – DELETED”* dropped **–28%** vs. a +18% category average.  These divergences suggest issues like overstock or weak demand.  In practice, we should review such subcategories (e.g. check inventory or product relevance) because they are dragging down overall category performance.

| Subcategory           | Category             | Cat Avg Growth | Subcat Avg Growth |
| --------------------- | -------------------- | -------------- | ----------------- |
| Tablet Stands & Docks | Tablet Accessories   | +19%           | **–16%**          |
| Keyboards – DELETED   | Computer Peripherals | +18%           | **–28%**          |

*Table: Example subcategory vs. category growth. “Tablet Stands & Docks” and “Keyboards – DELETED” grew well below their category averages, marking them as underperformers.*

## 🧭 Recommendations

* **Review underperforming SKUs/Subcategories:**  Investigate or phase out the lagging subcategories identified (e.g. *Tablet Stands & Docks*, *Keyboards – DELETED*). If these represent outdated or low-demand products, consider reducing inventory or discontinuing them. Such pruning frees up resources for better-selling lines.
* **Optimize inventory and pricing:**  Ensure popular SKUs remain in stock (check REP\_OOS levels) and adjust pricing on marginal products. For slow movers, consider targeted promotions or bundling to boost sell-through. Conversely, the most expensive items (e.g. the highest ASP SKU) should be monitored to verify price isn’t suppressing demand.
* **Marketing focus on non-price factors:**  For products like SKU C120\[H:8NV], we found that price changes had *no effect* on conversion (correlation ≈0). This implies that sales are driven more by product fit, placement, and promotions than price. Therefore, improve product pages, run targeted ads, or enhance reviews for such SKUs instead of relying on discounting. Emphasize marketing strategies (e.g. new imagery or bundles) for items with flat price elasticity.

## ⚠️ Caveats & Assumptions

* **ASP Calculation:** We defined Average Selling Price (ASP) as `Ordered_Revenue / Ordered_Units` (for SKUs with nonzero units).
* **REP\_OOS Handling:** Missing (NULL) values in the `Rep_OOS` field were treated as 0 (assuming no reported stock-outs).
* **Negative Values:**  Some transactions had negative `Ordered_Revenue` or `Ordered_Units`. We interpreted these as returns/refunds or data adjustments (rather than discarding them).
* **Outliers:** Many numerical fields (revenue, units, etc.) are highly skewed by extreme outliers.  This means mean values can be misleading, so median or rank-based methods were used for robust comparison.

## 🔗 Technical Artifacts

Colab Notebook: https://colab.research.google.com/drive/1OGIO8yaJgK4VThVPq8-C2eHs96t-bTF7?usp=sharing

