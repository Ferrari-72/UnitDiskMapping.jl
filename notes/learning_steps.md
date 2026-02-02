# Learning Steps for Understanding Gadget Verification

## Step 1: Read the Understanding Document
Open `notes/understanding_test_gadgets.md` and read it carefully:
- Start with "The Big Picture" to understand the overall goal
- Go through "Line-by-Line Understanding" section by section
- Read "Summary" at the end

**Time:** ~15-20 minutes

## Step 2: Study the Test File
Open `test/gadgets.jl` and go through it line by line:
- Focus on lines 7-17 (the first test set)
- For each line, refer back to the understanding document
- Make sure you understand:
  - What each line does
  - Why it's needed
  - How it fits into the overall verification

**Time:** ~20-30 minutes

## Step 3: Run the Test (Optional)
If you want to see it in action:

```julia
# In Julia REPL, run:
using Pkg
Pkg.activate(".")
include("test/gadgets.jl")
```

This will show you:
- Which gadgets are being tested
- Whether all tests pass
- Any errors if something goes wrong

## Step 4: Understand Key Concepts
Make sure you understand these concepts:

1. **Reduced α-tensor**: A lookup table for MIS sizes under different boundary configurations
2. **Constant difference**: Why `α̃(R')_s = α̃(P)_s + c` must hold
3. **Theorem 3.7**: The necessary and sufficient condition for gadget replacement

## Step 5: Ask Questions
If you encounter anything unclear:
- What is a "boundary configuration"?
- Why do we need "reduced" α-tensor?
- What happens if the difference is not constant?
- How does this relate to the original paper?

## Step 6: Explore Further (Optional)
Once you understand the test:
- Look at `src/utils.jl` to see how `is_diff_by_const` works
- Check `src/extracting_results.jl` to see pre-computed `mis_overhead` values
- Read `gadget_verification_math.typ` for the mathematical proof

## Checklist

Before moving on, make sure you can answer:
- [ ] What is the test trying to verify?
- [ ] What does each line (7-17) do?
- [ ] Why do we check for constant difference?
- [ ] What happens if a gadget fails the test?
- [ ] How does this relate to Theorem 3.7?


