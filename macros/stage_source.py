from sqlglot import exp
from sqlmesh import macro

@macro()
def stage_source(evaluator):
    if evaluator.runtime_stage == "testing" or getattr(evaluator, "is_test", False):
        return exp.to_table("raw_stage_data")

    raw_snowflake_syntax = "@POC_CICD.DEMO.TRANSACTIONS_STAGE/transactions/ (FILE_FORMAT => 'POC_CICD.DEMO.LOAD_CSV_FORMAT')"
    
    return exp.Table(this=exp.Identifier(this=raw_snowflake_syntax, quoted=False))