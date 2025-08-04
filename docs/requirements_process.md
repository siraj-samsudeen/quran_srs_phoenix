# Requirements Gathering for Software Projects

## Overview
What is best way to capture the requirements for a project, without writing too much? 

BDD (Behavior-Driven Development) excels at providing detailed feature descriptions through user stories and multiple scenarios per user story. However, this creates a **vertical perspective** - deep understanding of individual features but lacking the broader system view. This approach makes it difficult to see how different parts of the system connect and interact.

But we miss the horizontal perspective that connects the different parts of the system. We can get this by writing user journeys that cover the whole system or at least the major parts of it. This gives us the big picture view of how different parts of the system are connected.

User journeys alone should give us enough information to identify the tables in the system - Data models are the foundation of the system as many requirements just boil down to CRUD operations on tables. 

We can use this to autogenerate the code and the tests for all the usual parts - 80% of the system. Rest 20% can be more complex requirements for which we can write detailed scenarios. 

### Key Approach: User Journey-Driven Requirements
- **Solution**: Start with user journeys for big picture view (80% coverage) and detail complex scenarios as needed(20% coverage)
- **Foundation**: Data models emerge naturally from journey steps
- **Process**: Journey → Transactions → Tables → Operations -> Reports

### Core Components to Capture
- **User Journeys**: One per system/role covering major workflows
- **Transaction Analysis**: WHO, WHEN, WHERE, HOW, HOW MUCH
- **Data Models**: Tables and attributes from journey steps
- **Seed Data**: Sample records that evolve with requirements
- **Operations**: CRUD permissions, validations, business rules, workflows
- **Reporting**: Reports and calculations for each journey step


### Transaction Analysis Framework
For each step in the user journey, we can ask whether it is a transaction on its own, meriting capturing the data about it in a table or just a supporting step. If it is a transaction, we can capture the following:

- **WHO**: People involved (Employees, Customers, Suppliers)
- **WHEN**: Temporal aspects (Date, Time)
- **WHERE**: Location information
- **HOW**: Method or type (Transaction Type, Document Type)
- **HOW MUCH/MANY**: Quantities to capture
- **INPUT/OUTPUT**: Data flowing in and out of each step

This analysis naturally identifies:
- Entities/Tables needed
- Attributes/Columns for each table
- Relationships between tables

### Operational Requirements

Once tables are identified, capture operational details:

1. **CRUD Operations**: Assume all 4 operations needed for each table
2. **Permission Rules**: Which roles can perform which operations on which tables
3. **Validation Rules**: 
   - Field-level (e.g., number > 0, birth date > 1900)
   - Business rules spanning multiple fields
4. **Business Logic**: Complex rules beyond simple validation (e.g., stock availability checks)
5. **Workflows**: Multi-step processes like approval chains (e.g., orders > $500 need manager approval)

### Reporting and Analysis Layer

Complete the requirements by adding reporting perspective:

- **Step-Level Reports**: What reports are needed at each journey step
- **Journey-Level Reports**: Overall analytics for complete workflows
- **Calculations**: Any computed fields or aggregations needed for reporting

### Implementation Strategy

1. **Start with User Journeys**: Map out complete workflows
2. **Extract Data Models**: Identify tables from transaction steps
3. **Prepare Seed Data**: Create realistic test data for each table
4. **Generate Standard Code**: Auto-generate CRUD operations (80%)
5. **Detail Complex Scenarios**: Write specific scenarios for remaining 20%
6. **Layer in Operations**: Add permissions, validations, workflows
7. **Define Reports**: Specify analytics and calculations needed

This approach minimizes documentation while maximizing system understanding and provides a clear path from requirements to implementation.

### Testing Strategy

**80% - Generated Tests**:
- Phoenix generators create basic CRUD tests automatically
- These cover controller actions, context functions, and schema validations

**20% - Custom Tests to Write First**:
1. **Complex Validation Tests**: Write before implementing business rules
2. **Workflow Tests**: Define expected state transitions before coding
3. **Integration Tests**: Specify how features work together
4. **Report Tests**: Verify calculations and data aggregation

**Test-First Approach for Custom Code**:
```
1. Identify custom requirement from journey
2. Write test describing expected behavior
3. Run test (it fails)
4. Implement minimal code to pass
5. Refactor if needed
```

## Example: Amazon Customer Purchase Journey

# User Journey: Shopping Flow

**Journey Overview**:
- Actor: Registered Customer
- Goal: Find and purchase a product

### Journey Steps:
1. Visit homepage
2. Search or browse categories
3. View product details
4. Add to cart
5. Checkout and pay
6. Get confirmation and tracking link


**Step-by-Step Analysis**:

**Step 1: Search for product**
- Transaction?: No (get products with a search query)
- Supporting step for finding products

**Step 2: View product details**
- Transaction?: No (list products)
- May track for analytics later

**Step 3: Add to cart**
- Transaction?: Yes
- Transaction Table?: cart_items
- WHO: Customer 
- WHAT: Product
- WHEN: added_at timestamp
- WHERE: N/A
- HOW: N/A
- HOW MUCH: quantity
- INPUT: product_id, quantity, user_id
- OUTPUT: cart_item_id

**Step 4: View cart**
- Transaction?: No (list cart items)

**Step 5: Checkout - Enter shipping**
- Transaction?: Yes (creating/selecting shipping address)
- Transaction Table?: addresses (or shipping_addresses)
- WHO: Customer
- WHAT: Shipping address
- WHEN: created_at
- WHERE: delivery_location
- HOW: Address type (home/work/etc)
- HOW MUCH: N/A
- INPUT: address fields
- OUTPUT: address_id

**Step 6: Process payment**
- Transaction?: Yes
- Transaction Table?: payments
- WHO: Customer
- WHAT: Payment
- WHEN: timestamp
- WHERE: N/A
- HOW: payment_method (card/paypal/etc)
- HOW MUCH: amount
- INPUT: payment details, order_id, order_total
- OUTPUT: payment_id

**Derived Tables**:
(Listed in order of creation to support foreign key dependencies)

**Master Tables** (relatively static data):
- users - id, email, password_hash, name, created_at
- products - id, name, description, price, stock_quantity, created_at
- payment_methods - id, name, type (card/paypal/etc)

**Transaction Tables** (capture business events):
- cart_items - id, user_id, product_id, quantity, added_at
- addresses - id, user_id, street, city, state, zip, type, created_at
- orders - id, user_id, address_id, total_amount, status, created_at
- payments - id, order_id, payment_method_id, amount, status, processed_at

## Table Specifications

### Master Tables

**users**
- Fields: id (uuid), email (string unique), password_hash (string), name (string), created_at (timestamp)
- Validations: email format, email uniqueness, password min 8 chars
- Business Rules: None
- Workflows: None

**products**
- Fields: id (uuid), name (string), description (text), price (decimal), stock_quantity (integer), created_at (timestamp)
- Validations: price > 0, stock_quantity >= 0, name required
- Business Rules: Cannot order more than stock_quantity
- Workflows: None

**payment_methods**
- Fields: id (uuid), name (string), type (enum: card/paypal/bank), active (boolean)
- Validations: type in allowed values
- Business Rules: None
- Workflows: None

### Transaction Tables

**cart_items**
- Fields: id (uuid), user_id (ref), product_id (ref), quantity (integer), added_at (timestamp)
- Validations: quantity > 0, quantity <= 99
- Business Rules: quantity cannot exceed product.stock_quantity
- Workflows: None

**addresses**
- Fields: id (uuid), user_id (ref), street (string), city (string), state (string), zip (string), type (enum: home/work/other), created_at (timestamp)
- Validations: all fields required, zip format validation
- Business Rules: None
- Workflows: None

**orders**
- Fields: id (uuid), user_id (ref), address_id (ref), total_amount (decimal), status (enum: pending/paid/shipped/delivered), created_at (timestamp)
- Validations: total_amount > 0
- Business Rules: total_amount must equal sum of order items
- Workflows: Status transitions (pending → paid → shipped → delivered)

**payments**
- Fields: id (uuid), order_id (ref), payment_method_id (ref), amount (decimal), status (enum: pending/completed/failed), processed_at (timestamp)
- Validations: amount > 0
- Business Rules: amount must equal order.total_amount
- Workflows: Retry failed payments, refund process

### Cross-Table Business Rules
1. Order cannot be created without items in cart
2. Payment triggers order status change to "paid"
3. Stock quantity decreases when order is paid
4. User cannot checkout with empty cart

### Cross-Table Workflows
1. **Order Fulfillment**: Payment confirmed → Update order status → Decrease stock → Send confirmation → Create shipment
2. **Abandoned Cart**: Cart items older than 24 hours → Send reminder email → Delete after 7 days

## Custom Tests Required

Beyond the auto-generated CRUD tests, focus on tests that span multiple tables:

### Integration Tests (Full User Journey)
1. `test "complete purchase journey from search to order confirmation"`
   - Start with user login
   - Search for product
   - Add to cart
   - Checkout with address
   - Process payment
   - Verify order created and stock decreased

### Cross-Table Workflow Tests
2. `test "payment completion triggers order status update and stock decrease"`
3. `test "order cancellation restores product stock"`
4. `test "abandoned cart cleanup removes old items and frees stock"`

### Cross-Table Business Rule Tests
5. `test "cannot checkout when cart items exceed available stock"`
6. `test "order total must equal sum of cart items at checkout"`
7. `test "applying coupon updates order total correctly"`

### Report Tests
8. `test "daily sales report aggregates orders correctly"`
9. `test "inventory report reflects real-time stock changes"`
10. `test "customer lifetime value includes all completed orders"`

**Note**: Each table should also have tests for:
- Every validation rule (tested in schema tests)
- Every business rule specific to that table
- Every calculation or derived field

These are typically covered by the auto-generated tests or added to the schema test files.

## Seed Data Evolution

### Initial Seed Data (After identifying tables)

**users**
```
1. john@example.com, "John Doe"
2. jane@example.com, "Jane Smith"
3. admin@example.com, "Admin User"
```

**products**
```
1. "iPhone 15 Pro", "Latest iPhone", $999, stock: 50
2. "Organic Coffee", "Premium beans", $12.99, stock: 200
3. "Winter Jacket", "Warm jacket", $149.99, stock: 15
```

### Progressive Seed Data (As rules emerge)

**After adding "stock validation"**
```
4. "Limited Edition Book", $29.99, stock: 1 (test minimum stock)
5. "Digital Gift Card", $50, stock: 9999 (unlimited stock)
```

**After adding "quantity limits"**
```
6. "Bulk Rice 25kg", $45, stock: 10, max_order_quantity: 2
```

**After adding "order approval workflow"**
```
Order 1: Total $450 (no approval needed)
Order 2: Total $501 (triggers manager approval)
```

## Reporting Requirements

### Journey-Level Reports

**1. Sales Dashboard**
- Purpose: Executive overview of business performance
- Tables: orders, order_items, products, users
- Metrics:
  - Total revenue (daily/weekly/monthly)
  - Order count and average order value
  - Top selling products
  - Customer acquisition rate
- Frequency: Real-time with daily snapshots

**2. Customer Lifetime Value**
- Purpose: Understand customer profitability
- Tables: users, orders, payments
- Metrics:
  - Total spent per customer
  - Order frequency
  - Average time between orders
- Frequency: Weekly

### Step-Level Reports

**Step 1-2: Product Discovery**
- **Search Analytics Report**
  - Popular search terms
  - Search-to-view conversion rate
  - Products with no search results

**Step 3: Cart Management**
- **Cart Abandonment Report**
  - Items frequently added but not purchased
  - Average cart abandonment rate
  - Time from add-to-cart to purchase

**Step 6: Payment Processing**
- **Payment Success Report**
  - Payment method success rates
  - Failed payment reasons
  - Average processing time

### Operational Reports

**Inventory Report**
- Current stock levels
- Products below reorder point
- Stock turnover rate
- Dead stock (no sales in 90 days)

**Order Fulfillment Report**
- Orders by status
- Average time in each status
- Delayed shipments
- Delivery success rate

## Summary

This example demonstrates the complete requirements gathering process:

1. ✅ Started with user journey (6 steps)
2. ✅ Identified transactions using 5W+H analysis
3. ✅ Extracted data models (7 tables)
4. ✅ Created seed data that evolves with requirements
5. ✅ Defined operational requirements (validations, business rules, workflows)
6. ✅ Specified reporting needs (journey-level and step-level)
7. ✅ Identified custom tests beyond CRUD

The process captures ~80% requirements that can be auto-generated, clearly identifies the ~20% requiring custom code, and provides a complete blueprint for implementation.