#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): grep-only checks derived from skill rules.
# Exit 2 + stderr feeds violations back to the model. Never runs lint/tsc/build.
set -u
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

case "$file" in
  */node_modules/*|*/dist/*|*/drizzle/migrations/*|*/orval/*|*/services/v1/*|*.d.ts|*routeTree.gen.ts) exit 0 ;;
esac

errs=()
add() { errs+=("$1"); }
hits() { grep -nE "$1" "$file" | head -3 | sed 's/^/    /'; }

is_ts=0; case "$file" in *.ts|*.tsx) is_ts=1 ;; esac
is_test=0; case "$file" in *__tests__*|*.spec.ts|*.test.ts|*.test.tsx|*.e2e.ts) is_test=1 ;; esac
is_web=0; case "$file" in */src/pages/*|*/src/components/*|*/src/routes/*|*/src/schemas/*|*/src/hooks/*) is_web=1 ;; esac
is_api=0; case "$file" in */src/modules/*|*/src/infrastructure/*) is_api=1 ;; esac

if [ $is_ts -eq 1 ]; then
  if grep -nE '^\s*//[^/]|^\s*/\*|^\s*\*\s' "$file" | grep -vE 'eslint-disable|@ts-|<reference|https?://' | grep -q .; then
    add "[no-comments] comentário em $file (regra: nenhum comentário, nome descritivo resolve)"
  fi
  if grep -qE ':\s*any\b|<any>|\bas any\b' "$file"; then
    add "[no-any] uso de any em $file"
  fi
  if [ $is_test -eq 0 ] && grep -qE 'console\.(log|debug)' "$file"; then
    add "[no-console] console.log em $file"
  fi
fi

if [ $is_web -eq 1 ] && [ $is_ts -eq 1 ]; then
  grep -qE '\bforwardRef\b' "$file" && add "[frontend-component] forwardRef proibido (React 19, ref é prop normal)"
  grep -qE '\b[A-Z][A-Za-z]+\.(Root|Trigger|Content|Item|Header|Body|Footer)\b' "$file" && add "[frontend-component] dot notation proibida, use ComponentNameRoot (flat export)"
  base=$(basename "$file")
  case "$base" in *[A-Z_]*) case "$base" in \$*|_*|*.tsx|*.ts) echo "$base" | grep -qE '^[a-z0-9$._-]+$' || add "[frontend-component] arquivo deve ser kebab-case: $base" ;; esac ;; esac
  if [ $is_test -eq 0 ] && grep -qE '>[[:space:]]*[[:alpha:]][[:alpha:] ,.!?]{3,}[[:space:]]*<' "$file"; then
    add "[frontend-locale] possível string visível hardcoded no JSX (use i18n)"
  fi
  if grep -nE '\?\?\s*""|\?\?\s*"-"|\|\|\s*""|=\s*""\s*[,;)]' "$file" | grep -q .; then
    add "[frontend-form] literal \"\" ou \"-\" hardcoded, use Strings.EMPTY/Strings.UNDEFINED"
  fi
  if grep -qE 'zodResolver\(' "$file" && ! echo "$file" | grep -q '_schemas/'; then
    add "[frontend-form] zodResolver inline, exporte 'resolver' do schema em _schemas/"
  fi
  if grep -qE 'toast\.dispatch' "$file" && grep -qE 'onError' "$file" && ! grep -q 'ignoreError' "$file"; then
    add "[frontend-table/stepper] onError com toast.dispatch exige meta: { ignoreError: true }"
  fi
  if grep -qE 'table\.getState\(\)\.pagination' "$file"; then
    add "[frontend-table] paginação de servidor via useFilter, não table.getState().pagination"
  fi
  case "$file" in
    */src/pages/*/index.tsx|*/src/pages/*/create/index.tsx|*/src/pages/*/edit/*/index.tsx)
      if grep -q 'createFileRoute' "$file"; then
        grep -q 'beforeLoad' "$file" || add "[frontend-page] rota sem beforeLoad: require({ can, features })"
        grep -q 'errorComponent' "$file" || add "[frontend-page] rota sem errorComponent: ErrorBoundary"
      fi ;;
  esac
  if grep -qE 'API<[^>]*>\(\s*\{\s*url' "$file"; then
    add "[web] API<T>({ url }) cru, use função gerada pelo orval"
  fi
fi

if [ $is_api -eq 1 ] && [ $is_ts -eq 1 ] && [ $is_test -eq 0 ]; then
  case "$file" in
    *.repository.ts)
      grep -qE 'db\.delete\(|\.delete\(' "$file" && add "[backend-sql] delete físico proibido, lifecycle é UPDATE"
      grep -qE '\.(values|set)\(\s*\{?\s*\.\.\.' "$file" && add "[backend-sql] spread em values()/set(), monte campo a campo"
      grep -qE 'ilike\(' "$file" && ! grep -q 'escapeLike' "$file" && add "[backend-sql] ilike sem escapeLike"
      case "$file" in
        *-query.repository.ts) grep -qE '\.(insert|update)\(' "$file" && add "[backend-sql] query repository só SELECT" ;;
        *-command.repository.ts) grep -qE '\.select\(' "$file" && add "[backend-sql] command repository só INSERT/UPDATE" ;;
      esac
      if grep -qE 'from\(|innerJoin|leftJoin' "$file" && ! grep -q 'organizationId' "$file"; then
        add "[backend-sql] repository sem organizationId (vazamento de tenant)"
      fi ;;
    *.controller.ts)
      grep -qE '@(Get|Post|Put|Patch|Delete)\(' "$file" && ! grep -q '@Can' "$file" && add "[backend-cqrs/rule] controller sem @Can"
      grep -qE '@(Get|Post|Put|Patch|Delete)\(' "$file" && ! grep -q '@Feature' "$file" && add "[backend-cqrs/rule] controller sem @Feature"
      grep -qE '@(Post|Put|Patch|Delete)\(' "$file" && ! grep -q '@Audit' "$file" && add "[backend-cqrs] write sem @Audit()"
      grep -qE '@Param\(' "$file" && ! grep -q 'ParseIdPipe' "$file" && add "[backend-cqrs] @Param sem ParseIdPipe"
      grep -qE "@Can\(\s*['\"\`]" "$file" && add "[backend-rule] @Can com literal, use Policies.X.Y.Z"
      grep -qE "@Feature\(\s*['\"\`]" "$file" && add "[backend-rule] @Feature com literal, use Features.X.Y"
      grep -qE '@Body\(\)[^)]*organizationId|@Query\(\)[^)]*organizationId' "$file" && add "[backend-cqrs] organizationId só de @CurrentUser" ;;
    *.handler.ts)
      grep -qE '\.execute\(' "$file" && grep -E '(queryBus|commandBus)\.execute\(' "$file" | grep -vqE 'execute<' && add "[backend-cqrs] bus.execute sem tipagem genérica execute<Query, Dto>"
      grep -qE 'catch\s*\(' "$file" && add "[backend-cqrs] try/catch amplo proibido, use BusinessException" ;;
  esac
  case "$file" in
    *.dto.ts|*/dtos/*)
      if grep -qE '@ApiProperty\(\s*\)' "$file"; then add "[backend-dto] @ApiProperty() sem type explícito"; fi
      grep -nE '@ApiProperty\(\{' "$file" | grep -vqE 'type:|enum:' && add "[backend-dto] @ApiProperty sem type"
      grep -qE '@ApiPropertyOptional' "$file" && case "$file" in */http/dtos/*) add "[backend-dto] response DTO não usa @ApiPropertyOptional" ;; esac
      grep -qE '\b(organizationId|deletedAt|userId)\b' "$file" && case "$file" in */http/dtos/*) add "[backend-dto] response DTO expondo organizationId/deletedAt/userId" ;; esac
      grep -qE '@Type\(\(\)\s*=>\s*Boolean\)' "$file" && add "[backend-filter] @Type(() => Boolean) proibido, use @Transform 'true'/'false' + @IsBoolean"
      grep -nE '@(Is[A-Za-z]+|Min|Max|MinLength|MaxLength|Length|Matches|ArrayMinSize|ArrayMaxSize)\(' "$file" | grep -vq 'message' || true
      if grep -nE '@(Is[A-Za-z]+|MinLength|MaxLength|Length|Min|Max|Matches)\(' "$file" | grep -vE 'message|IsOptional' | grep -q .; then
        add "[backend-locale] validador class-validator sem { message: '<key>' }"
      fi
      grep -nE '\b(nome|descricao|sigla|codigo|valor|endereco|telefone|cidade|estado|bairro|numero|status)\??:' "$file" | grep -q . && add "[backend-locale] propriedade de DTO em português, use inglês e mapeie no service" ;;
  esac
  case "$file" in
    *.schema.ts)
      grep -qE '\b(decimal|numeric|real|doublePrecision|float)\(' "$file" && add "[backend-schema] money/quantidade não usa decimal/float, use integer (centavos/escala)"
      grep -qE '\bstatus\b\s*:\s*(varchar|text|integer)' "$file" && add "[backend-schema] sem coluna status para lifecycle, use archivedAt/deletedAt"
      grep -qE "varchar\(\s*['\"][a-zA-Z_]+['\"]\s*\)" "$file" && add "[backend-schema] varchar sem length deliberado"
      grep -qE 'organization_id|organizationId' "$file" && ! grep -qE 'index\(|uniqueIndex\(' "$file" && add "[backend-schema] tabela com organization_id sem index liderado por organization_id" ;;
  esac
  grep -qE 'throw new (BadRequestException|NotFoundException|ForbiddenException|UnauthorizedException|ConflictException|HttpException|Error)\(' "$file" && add "[backend-locale] throw nativo, use BusinessException(CodeExceptions.X, HttpStatus.Y)"
  grep -qE "BusinessException\(\s*['\"\`]" "$file" && add "[backend-locale] BusinessException com string literal, use CodeExceptions"
  case "$file" in */helpers/*) case "$file" in */src/http/helpers/*|*/src/infrastructure/providers/*/helpers/*) ;; *) add "[backend-provider] helpers/ dentro de módulo proibido, só global" ;; esac ;; esac
fi

if [ ${#errs[@]} -gt 0 ]; then
  { echo "Violações de skill em $file:"; for e in "${errs[@]}"; do echo "  - $e"; done; } >&2
  exit 2
fi
exit 0
