const express = require('express');
const router = express.Router(); // ✅ REQUIRED: Sets up the router

const auth = require('../middleware/auth');
const Expense = require('../models/Expense');

// ✅ Get all expenses for the logged-in user
router.get('/', auth, async (req, res) => {
  try {
    console.log('📥 Getting expenses for userId:', req.userId); // Add this line

    const expenses = await Expense.find({ userId: req.userId });
    res.json(expenses);
  } catch (err) {
    console.error('❌ Error fetching expenses:', err); // log full error
    res.status(500).json({ message: 'Error fetching expenses' });
  }
});

// ✅ Create a new expense for the logged-in user
router.post('/', auth, async (req, res) => {
  try {
    const { title, amount, category, date } = req.body;
    const expense = new Expense({
      title,
      amount,
      category,
      date,
      userId: req.userId,
    });
    await expense.save();
    res.status(201).json(expense);
  } catch (err) {
    console.error('Error creating expense:', err); // 🔍 check console log
    res.status(500).json({ message: 'Error creating expense' });
  }
});
// ✅ Update an expense
router.put('/:id', auth, async (req, res) => {
  try {
    const { title, amount, category, date } = req.body;
    const expenseId = req.params.id;

    // 🔐 Make sure the user owns this expense
    const expense = await Expense.findOne({ _id: expenseId, userId: req.userId });
    if (!expense) {
      return res.status(404).json({ message: 'Expense not found or unauthorized' });
    }

    // ✏️ Update values
    expense.title = title;
    expense.amount = amount;
    expense.category = category;
    expense.date = date;

    await expense.save();
    res.status(200).json({ message: 'Expense updated successfully', expense });
  } catch (err) {
    console.error('❌ Error updating expense:', err);
    res.status(500).json({ message: 'Server error while updating expense' });
  }
});

// ✅ Delete an expense
router.delete('/:id', auth, async (req, res) => {
  try {
    const expenseId = req.params.id;

    const deleted = await Expense.findOneAndDelete({
      _id: expenseId,
      userId: req.userId, // Only delete if it belongs to logged-in user
    });

    if (!deleted) {
      return res.status(404).json({ message: 'Expense not found or unauthorized' });
    }

    res.status(200).json({ message: 'Expense deleted successfully' });
  } catch (err) {
    console.error('❌ Error deleting expense:', err);
    res.status(500).json({ message: 'Server error while deleting expense' });
  }
});


module.exports = router;
