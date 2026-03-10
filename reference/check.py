"""
Run analytics queries to verify the data warehouse is working.

Usage:
    uv run python check.py
"""

import utils.db as db


def main() -> None:
    conn = db.connect()
    db.ensure_schemas(conn)

    print("=== Row counts ===")
    rows = conn.execute(f"""
        SELECT TABLE_NAME, TABLE_ROW_COUNT
        FROM EXA_ALL_TABLES
        WHERE TABLE_SCHEMA = '{db.WAREHOUSE_SCHEMA}'
          AND TABLE_NAME IN ('PRACTICE', 'CHEMICAL', 'PRESCRIPTION')
    """).fetchall()
    counts = {table_name: int(row_count or 0) for table_name, row_count in rows}
    for table in ["PRACTICE", "CHEMICAL", "PRESCRIPTION"]:
        count = counts.get(table, 0)
        print(f"  {table}: {count:,} rows")

    print()
    print("=== Top 10 chemicals by total cost ===")
    rows = conn.execute(f"""
        SELECT sub.CHEMICAL_CODE, c.CHEMICAL_NAME, sub.TOTAL_ITEMS, sub.TOTAL_COST
        FROM (
            SELECT CHEMICAL_CODE, SUM(ITEMS) AS TOTAL_ITEMS, SUM(ACTUAL_COST) AS TOTAL_COST
            FROM {db.WAREHOUSE_SCHEMA}.PRESCRIPTION
            GROUP BY CHEMICAL_CODE
        ) sub
        LEFT JOIN {db.WAREHOUSE_SCHEMA}.CHEMICAL c
            ON sub.CHEMICAL_CODE = c.CHEMICAL_CODE
        ORDER BY sub.TOTAL_COST DESC
        LIMIT 10
    """).fetchall()

    print(f"  {'CHEM_CODE':<16} {'CHEMICAL':<40} {'ITEMS':>10} {'COST':>12}")
    print(f"  {'-'*16} {'-'*40} {'-'*10} {'-'*12}")
    for row in rows:
        print(f"  {row[0]:<16} {(row[1] or 'N/A'):<40} {int(row[2]):>10,} {float(row[3]):>12,.2f}")

    print()
    print("=== Top 10 practices by prescription volume ===")
    rows = conn.execute(f"""
        SELECT sub.PRACTICE_CODE, pr.PRACTICE_NAME, pr.POSTCODE, sub.TOTAL_ITEMS
        FROM (
            SELECT PRACTICE_CODE, SUM(ITEMS) AS TOTAL_ITEMS
            FROM {db.WAREHOUSE_SCHEMA}.PRESCRIPTION
            GROUP BY PRACTICE_CODE
        ) sub
        LEFT JOIN {db.WAREHOUSE_SCHEMA}.PRACTICE pr
            ON sub.PRACTICE_CODE = pr.PRACTICE_CODE
        ORDER BY sub.TOTAL_ITEMS DESC
        LIMIT 10
    """).fetchall()

    print(f"  {'CODE':<10} {'PRACTICE':<40} {'POSTCODE':<10} {'ITEMS':>10}")
    print(f"  {'-'*10} {'-'*40} {'-'*10} {'-'*10}")
    for row in rows:
        print(f"  {row[0]:<10} {(row[1] or 'N/A'):<40} {(row[2] or 'N/A'):<10} {int(row[3]):>10,}")

    conn.close()


if __name__ == "__main__":
    main()
