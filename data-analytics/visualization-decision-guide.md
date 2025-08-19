# Chart Selection & Visualization Decision Guide

A comprehensive decision framework for selecting the most effective chart types and visualization patterns based on data relationships, user goals, and storytelling objectives. This guide eliminates guesswork and ensures optimal data communication.

## 🎯 Core Decision Framework

### **Primary Question**: What story are you trying to tell?

```
Data Story Type → Chart Category → Specific Chart → Design Considerations
```

## 📊 Chart Selection Decision Tree

### **1. COMPARISON** - *"How do values differ between categories?"*

#### **Few Categories (2-7 items)**
- **Bar Chart (Vertical)** ✅ Best Choice
  - Use when: Category names are short
  - Advantages: Easy comparison, clear ranking
  - Design: Start axis at zero, sort by value when possible

- **Bar Chart (Horizontal)** ✅ Best Choice  
  - Use when: Category names are long
  - Advantages: More space for labels, easier reading
  - Design: Alphabetical or value-based ordering

#### **Many Categories (8+ items)**
- **Horizontal Bar Chart** ✅ Recommended
- **Dot Plot** ✅ Alternative - Less visual clutter
- **Avoid**: Pie charts, vertical bars (label crowding)

#### **Comparing Parts of a Whole**
- **Stacked Bar Chart** ✅ When: Few categories, clear hierarchy
- **Pie Chart** ⚠️ Only when: 2-3 slices, percentages are key
- **Donut Chart** ❌ Avoid: Harder to read than pie charts
- **Treemap** ✅ When: Many categories, size matters

### **2. TRENDS** - *"How do values change over time?"*

#### **Single Metric Over Time**
- **Line Chart** ✅ Best Choice
  - Use when: Continuous time series, showing trends
  - Design: Direct labeling preferred over legends
  - Avoid: More than 5-7 lines for clarity

#### **Multiple Metrics Over Time**
- **Multiple Line Chart** ✅ When: <5 related metrics
- **Small Multiples** ✅ When: >5 metrics or different scales
- **Stacked Area Chart** ✅ When: Part-to-whole relationships over time

#### **Seasonal or Cyclical Data**
- **Line Chart with Annotations** ✅ Mark seasonal patterns
- **Heat Map (Calendar)** ✅ When: Daily patterns over months/years
- **Radar Chart** ⚠️ Only when: Cyclical nature is key message

### **3. DISTRIBUTION** - *"What does the data spread look like?"*

#### **Single Variable Distribution**
- **Histogram** ✅ Best Choice
  - Use when: Understanding data distribution shape
  - Design: Choose bin count carefully (sqrt of data points)
  - Include: Mean, median lines when helpful

- **Box Plot** ✅ Statistical Summary
  - Use when: Highlighting outliers, quartiles
  - Advantage: Compact representation of distribution statistics

#### **Comparing Distributions**
- **Multiple Histograms (Small Multiples)** ✅ Clear comparison
- **Violin Plot** ✅ Advanced: Distribution shape + statistics
- **Ridge Plot** ✅ Many distributions vertically stacked

#### **Two Variable Relationship**
- **Scatter Plot** ✅ Best Choice
  - Use when: Exploring correlation, identifying patterns
  - Enhancement: Size/color for third dimension
  - Include: Trend line when correlation exists

### **4. COMPOSITION** - *"What makes up the whole?"*

#### **Static Composition**
- **Pie Chart** ✅ Only when: 2-3 categories, percentages matter
- **Horizontal Bar Chart** ✅ Better alternative: Easier comparison
- **Treemap** ✅ When: Many components, hierarchical data

#### **Changing Composition Over Time**
- **Stacked Area Chart** ✅ Best Choice
  - Use when: Showing both total and component trends
  - Design: Order categories by size or importance

- **Stacked Bar Chart (Time Series)** ✅ Alternative
  - Use when: Discrete time periods
  - Better for: Precise value reading

### **5. GEOSPATIAL** - *"Where do values occur geographically?"*

#### **Regional Comparisons**
- **Choropleth Map** ✅ Best Choice
  - Use when: Data varies by geographic region
  - Design: Use sequential color scale, avoid red/green

- **Symbol Map** ✅ When: Point locations matter
  - Use when: Specific locations, not regions
  - Design: Size proportional to values

#### **Alternative to Maps**
- **Horizontal Bar Chart** ✅ Often Better
  - Advantage: Easier precise comparison
  - Use when: Geography is not essential to story

## 🎨 Design Pattern Library

### **Color Strategy Decision Matrix**

| Data Type | Recommended Palette | Rationale |
|-----------|-------------------|-----------|
| **Categories** | Qualitative (distinct hues) | Maximum differentiation |
| **Sequential** | Single hue gradient | Shows progression |
| **Diverging** | Two-hue gradient with neutral center | Shows deviation from norm |
| **Positive/Negative** | Green/Red or Blue/Orange | Intuitive meaning |

### **Interactive Patterns**

#### **Hover States** ✅ Always Include
```
Basic Data Point: Value + Context
Time Series: Date + Value + % Change
Comparison: Rank + Value + Benchmark
Geographic: Location + Value + Regional Average
```

#### **Filter Patterns**
- **Dropdown** - 5+ options, single selection
- **Checkbox** - Multiple selections, <10 options  
- **Slider** - Continuous ranges, date ranges
- **Button Toggle** - 2-4 mutually exclusive options

#### **Drill-Down Hierarchy**
```
Level 1: High-level summary (dashboard view)
    ↓ (click/tap)
Level 2: Category breakdown (section view)
    ↓ (click/tap)  
Level 3: Individual records (detail view)
```

## 🚫 Anti-Patterns to Avoid

### **Chart Type Mistakes**
- **❌ Pie Charts**: When >5 categories or comparison is key
- **❌ 3D Charts**: Distort perception, harder to read  
- **❌ Dual Y-Axis**: Confusing, can mislead
- **❌ Stacked Bars**: When precise comparison needed
- **❌ Radar Charts**: Unless cyclical nature is essential

### **Design Mistakes**
- **❌ Non-Zero Baseline**: Exaggerates differences (except for focus views)
- **❌ Too Many Colors**: Cognitive overload, accessibility issues
- **❌ Legends for Single Series**: Wastes space, direct labeling better
- **❌ Rotation Labels**: Hard to read, use horizontal bars instead
- **❌ Gridlines Overload**: Should enhance, not distract

### **Interaction Mistakes**
- **❌ Hover Dependencies**: Critical info should be always visible
- **❌ Inconsistent Interactions**: Same gestures should behave identically
- **❌ No Loading States**: Users need feedback during data updates
- **❌ Deep Navigation**: >3 clicks to get to important insights

## 🎯 Use Case Templates

### **Executive Dashboard Charts**

#### **KPI Scorecard**
```
Format: Large number + trend indicator + context
Example: "$2.4M" + "↑12%" + "vs last month"
Chart Type: Number + sparkline
Color: Green (positive) / Red (negative)
```

#### **Performance Overview**
```
Primary: Horizontal bar chart (departments/regions)
Secondary: Line chart (trend over time)  
Interaction: Click bar → drill to detailed trend
Layout: Side-by-side or stacked vertically
```

### **Operational Dashboard Charts**

#### **Real-time Monitoring**
```
Primary: Time series line chart (last 24h)
Alert: Red zone highlighting for thresholds
Update: Every 1-5 minutes with smooth transitions
Context: Normal range shading
```

#### **Resource Utilization**
```
Primary: Stacked area chart (resource breakdown)
Secondary: Gauge charts (current utilization %)
Layout: Area chart top, gauges below
Colors: Sequential from low to high utilization
```

### **Analytical Dashboard Charts**

#### **Cohort Analysis**
```
Primary: Heat map (time vs cohort)
Color: Sequential (retention rate)
Interaction: Hover for exact percentages
Context: Average retention line overlay
```

#### **A/B Test Results**
```
Primary: Error bar chart (confidence intervals)
Secondary: Distribution plots (small multiples)
Stats: Statistical significance indicators
Layout: Main results top, distributions below
```

## 📱 Mobile-First Considerations

### **Chart Adaptations**
- **Simplify**: Reduce data points, focus on key insights
- **Vertical Layout**: Stack charts vertically instead of side-by-side
- **Touch Targets**: Minimum 44px for interactive elements
- **Progressive Disclosure**: Summary → detail on tap

### **Mobile-Optimized Chart Types**
- **✅ Vertical Bar Charts**: Natural fit for mobile screens
- **✅ Line Charts**: Work well with horizontal scrolling
- **✅ Simple Pie Charts**: Easy to understand on small screens
- **❌ Complex Scatter Plots**: Hard to interact with precisely
- **❌ Multi-series Line Charts**: Overlapping lines problematic

## 🔍 Accessibility Guidelines

### **Visual Accessibility**
- **Color Contrast**: Minimum 3:1 for large text, 4.5:1 for normal
- **Color Independence**: Never use color alone to convey information
- **Pattern/Texture**: Use in addition to color for differentiation
- **Font Size**: Minimum 12px for chart labels, 14px preferred

### **Interaction Accessibility**
- **Keyboard Navigation**: All interactive elements accessible via keyboard
- **Screen Reader Support**: Proper ARIA labels and descriptions  
- **Focus Indicators**: Clear visual focus states for keyboard users
- **Alternative Formats**: Provide data tables as alternative to complex charts

### **Cognitive Accessibility**
- **Clear Titles**: Descriptive, jargon-free chart titles
- **Context**: Always provide baseline or comparison context
- **Consistent Interactions**: Same interactions work the same way
- **Progressive Disclosure**: Don't overwhelm with too much information

## ✅ Chart Selection Checklist

### **Before Creating Any Chart**
- [ ] **Define the story**: What insight should users gain?
- [ ] **Identify the audience**: Technical vs non-technical users
- [ ] **Consider the context**: Standalone vs part of dashboard
- [ ] **Plan for mobile**: Will this work on small screens?

### **Chart Type Decision**
- [ ] **Data relationship**: Comparison, trend, distribution, composition, geographic?
- [ ] **Number of categories**: Few (<7) or many (8+)?
- [ ] **Time element**: Static snapshot or changes over time?
- [ ] **Precision needs**: Exact values or general patterns?

### **Design Implementation** 
- [ ] **Color accessibility**: Sufficient contrast, not color-dependent
- [ ] **Direct labeling**: Avoid legends when possible
- [ ] **Appropriate baseline**: Zero start unless focusing on range
- [ ] **Clear hierarchy**: Most important elements stand out

### **Interaction Design**
- [ ] **Hover states**: Provide additional context without cluttering
- [ ] **Mobile optimization**: Touch-friendly targets and gestures
- [ ] **Loading states**: Show progress during data updates
- [ ] **Error handling**: Graceful degradation when data unavailable

## 🛠️ Tool-Specific Implementations

### **Tableau Best Practices**
```
- Use calculated fields for custom metrics
- Leverage sets for dynamic grouping
- Implement parameter controls for user flexibility
- Use dashboard actions for interactivity
- Optimize for performance with data source filters
```

### **Power BI Patterns**
```
- Create measures using DAX for calculations
- Use bookmarks for interactive storytelling
- Implement RLS (Row Level Security) for data access
- Leverage AI visuals for automated insights
- Design for both desktop and mobile layouts
```

### **D3.js/Custom Development**
```
- Follow D3 margin conventions for consistent spacing
- Implement smooth transitions for engaging interactions
- Use semantic HTML and ARIA labels for accessibility
- Optimize rendering performance for large datasets  
- Provide fallback images or tables for older browsers
```

---

**Last Updated**: 2025-01-19  
**Next Review**: 2025-04-19  
**Owner**: Data Visualization Team