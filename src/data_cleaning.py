"""
Data cleaning utilities for Clarté Commerce analysis.
"""

import pandas as pd
import numpy as np


def load_transactions(path='../data/raw/transactions.csv'):
    """Load and parse transaction data."""
    df = pd.read_csv(path, parse_dates=['transaction_date'])
    df['year'] = df['transaction_date'].dt.year
    df['month'] = df['transaction_date'].dt.month
    df['year_month'] = df['transaction_date'].dt.to_period('M')
    return df


def load_customers(path='../data/raw/customers.csv'):
    """Load and parse customer data."""
    df = pd.read_csv(path, parse_dates=['registration_date'])
    return df


def load_products(path='../data/raw/products.csv'):
    """Load product catalog."""
    return pd.read_csv(path)


def remove_test_orders(transactions):
    """
    Remove internal test orders from transaction data.
    Test customers have IDs matching pattern CLR-TEST-*.
    
    Parameters
    ----------
    transactions : pd.DataFrame
    
    Returns
    -------
    pd.DataFrame with test orders removed
    int count of removed rows
    """
    mask = transactions['customer_id'].str.contains('TEST', na=False)
    n_removed = mask.sum()
    return transactions[~mask].copy(), n_removed


def flag_churn(transactions, threshold_days=180, snapshot_date=None):
    """
    Flag customers as churned based on inactivity threshold.
    
    Parameters
    ----------
    transactions : pd.DataFrame
    threshold_days : int, days of inactivity to consider churned
    snapshot_date : pd.Timestamp, reference date (default: max date in data)
    
    Returns
    -------
    pd.DataFrame with customer_id, last_purchase, days_since_last, is_churned
    """
    if snapshot_date is None:
        snapshot_date = transactions['transaction_date'].max()
    
    activity = transactions.groupby('customer_id').agg(
        first_purchase=('transaction_date', 'min'),
        last_purchase=('transaction_date', 'max'),
        total_transactions=('transaction_id', 'nunique'),
        total_spent=('total_amount', 'sum'),
        avg_order_value=('total_amount', 'mean')
    ).reset_index()
    
    activity['days_since_last'] = (snapshot_date - activity['last_purchase']).dt.days
    activity['is_churned'] = activity['days_since_last'] > threshold_days
    
    return activity