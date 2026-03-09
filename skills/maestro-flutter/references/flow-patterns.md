# Maestro Flow Patterns

## Login Flow

```yaml
# .maestro/flows/auth/login.yaml
appId: com.example.myapp
name: User Login
---
- launchApp:
    clearState: true

- extendedWaitUntil:
    visible: "Welcome"
    timeout: 10000

- tapOn:
    id: "email_field"
- inputText: ${TEST_EMAIL}

- tapOn:
    id: "password_field"
- inputText: ${TEST_PASSWORD}

- tapOn:
    id: "login_button"

- waitForAnimationToEnd
- extendedWaitUntil:
    visible: "Home"
    timeout: 10000

- assertVisible:
    id: "home_tab"

- takeScreenshot: "login_success"
```

## Browse Flow (with reusable login)

```yaml
# .maestro/flows/product/browse.yaml
appId: com.example.myapp
name: Browse Products
---
- launchApp

# Reuse login flow
- runFlow: flows/auth/login.yaml

- tapOn:
    id: "home_tab"
- waitForAnimationToEnd

- extendedWaitUntil:
    visible:
      id: "product_list"
    timeout: 10000

- scroll:
    direction: DOWN
- scroll:
    direction: DOWN

- takeScreenshot: "product_list"

- tapOn:
    id: "product_card"
    index: 0

- waitForAnimationToEnd
- assertVisible: "Product Details"
- assertVisible:
    id: "add_to_cart_button"

- takeScreenshot: "product_details"
```

## Add to Cart Flow

```yaml
# .maestro/flows/product/add_to_cart.yaml
appId: com.example.myapp
name: Add Product to Cart
---
- launchApp

- runFlow: flows/auth/login.yaml
- runFlow: flows/product/browse.yaml

- tapOn:
    id: "add_to_cart_button"

- assertVisible: "Added to cart"

- tapOn:
    id: "cart_tab"
- waitForAnimationToEnd

- assertVisible:
    id: "cart_item"

- takeScreenshot: "cart_with_item"
```

## Smoke Test (All Critical Paths)

```yaml
# .maestro/flows/smoke_test.yaml
appId: com.example.myapp
name: Smoke Test - All Critical Paths
---
- launchApp:
    clearState: true

# Onboarding (conditional)
- runFlow:
    when:
      visible: "Get Started"
    file: flows/onboarding/complete.yaml

# Auth
- runFlow: flows/auth/register.yaml
- takeScreenshot: "01_after_registration"
- runFlow: flows/auth/logout.yaml
- runFlow: flows/auth/login.yaml
- takeScreenshot: "02_after_login"

# Browse
- tapOn:
    id: "home_tab"
- waitForAnimationToEnd
- assertVisible:
    id: "product_list"
- takeScreenshot: "03_product_list"

# Add to Cart
- tapOn:
    id: "product_card"
    index: 0
- waitForAnimationToEnd
- tapOn:
    id: "add_to_cart_button"
- assertVisible: "Added to cart"

# Cart
- tapOn:
    id: "cart_tab"
- waitForAnimationToEnd
- assertVisible:
    id: "cart_item"
- takeScreenshot: "04_cart"

# Checkout
- tapOn: "Checkout"
- waitForAnimationToEnd
- assertVisible: "Order Summary"
- takeScreenshot: "05_checkout"

# Profile
- tapOn:
    id: "profile_tab"
- waitForAnimationToEnd
- assertVisible: ${TEST_EMAIL}
- takeScreenshot: "06_profile"

# Logout
- tapOn: "Logout"
- assertVisible: "Login"
- takeScreenshot: "07_logged_out"
```

---

## Flutter-Specific Tips

### Handle Loading States

```yaml
- tapOn: "Refresh"
- extendedWaitUntil:
    notVisible:
      id: "loading_indicator"
    timeout: 15000
- assertVisible:
    id: "content"
```

### Handle Riverpod State Changes

```yaml
# Action triggers Riverpod state change → UI updates
- tapOn:
    id: "add_to_cart_button"

- waitForAnimationToEnd
- extendedWaitUntil:
    visible: "Added to cart"
    timeout: 5000
```

### Handle Bottom Sheets

```yaml
- tapOn: "Show Options"
- waitForAnimationToEnd
- tapOn: "Option 1"

# Close by swiping down
- swipe:
    direction: DOWN
    duration: 300
```

### Handle Dialogs

```yaml
- tapOn: "Delete"
- assertVisible: "Are you sure?"
- tapOn: "Confirm"
- assertNotVisible: "Deleted item"
```

### Pull to Refresh

```yaml
- swipe:
    start: "50%,20%"
    end: "50%,80%"
    duration: 500
- waitForAnimationToEnd
```

### Tab Navigation

```yaml
# Bottom navigation
- tapOn:
    id: "home_tab"
- waitForAnimationToEnd
- assertVisible:
    id: "home_content"

# Verify other tabs
- tapOn:
    id: "profile_tab"
- waitForAnimationToEnd
- assertVisible:
    id: "profile_content"
```

### Form Validation

```yaml
# Submit empty form
- tapOn:
    id: "submit_button"

# Verify validation errors
- assertVisible: "Email is required"
- assertVisible: "Password is required"

# Fill valid data
- tapOn:
    id: "email_field"
- inputText: "valid@email.com"
- tapOn:
    id: "password_field"
- inputText: "ValidPass123!"

- tapOn:
    id: "submit_button"
- assertNotVisible: "Email is required"
```

---

## Writing Test Cases → Maestro Flows

### From PM test case to YAML flow:

**Test Case:** "User can login with valid credentials"
```yaml
# Maps to: .maestro/flows/auth/TC-001-login-valid.yaml
name: "TC-001: User can login with valid credentials"
---
- launchApp:
    clearState: true
- tapOn: { id: "email_field" }
- inputText: ${TEST_EMAIL}
- tapOn: { id: "password_field" }
- inputText: ${TEST_PASSWORD}
- tapOn: { id: "login_button" }
- assertVisible: { id: "home_tab" }
- takeScreenshot: "TC-001-pass"
```

**Test Case:** "Invalid password shows error"
```yaml
# Maps to: .maestro/flows/auth/TC-002-login-invalid.yaml
name: "TC-002: Invalid password shows error"
---
- launchApp:
    clearState: true
- tapOn: { id: "email_field" }
- inputText: ${TEST_EMAIL}
- tapOn: { id: "password_field" }
- inputText: "wrong_password"
- tapOn: { id: "login_button" }
- assertVisible: { id: "error_message" }
- takeScreenshot: "TC-002-pass"
```
