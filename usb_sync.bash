#!/usr/bin/env bash

EXECUTABLE="$(realpath "$0")"
ROOT_DIR="$(realpath "$(dirname "$0")")"

LOCAL_DIR=${ROOT_DIR}
LOCAL_WORK_DIR="${LOCAL_DIR}/work"
LOCAL_DOCS_DIR="${LOCAL_WORK_DIR}/documents"
LOCAL_PROJ_DIR="${LOCAL_WORK_DIR}/projects"
LOCAL_DOCS_BU_DIR="${LOCAL_WORK_DIR}/backup_documents"
LOCAL_PROJ_BU_DIR="${LOCAL_WORK_DIR}/backup_projects"

REMOTE_DIR=${HOME}
REMOTE_WORK_DIR="${REMOTE_DIR}/work"
REMOTE_DOCS_DIR="${REMOTE_WORK_DIR}/documents"
REMOTE_PROJ_DIR="${REMOTE_WORK_DIR}/projects"

VERBOSE=0
DRY_RUN=0
YES=0

VOID="/dev/null"
GEN32CHAR="cat /dev/urandom | tr -cd 'a-z0-9' | head -c 32"
TIMESTAMP="date +%Y.%m.%d-%H.%M.%S"
MD="mkdir --parents"

RSYNC="rsync --archive --update"

confirm_choice()
{
  if [ ${YES} -eq 1 ]
  then 
    return 0
  fi
  
  TEXT="Продолжить? [д/Н] "
  if [ ! "$1" == "" ]
  then 
    TEXT="$1 [д/Н] "
  fi
  
  read -p "${TEXT}" -r
  #echo
  if [ "$REPLY" == "Y" ] || [ "$REPLY" == "y" ] || [ "$REPLY" == "Д" ] || [ "$REPLY" == "д" ]
  then
    return 0
  fi
  
  return 1
}

report_message()
{
  printf '%s\n' "$1" >&2
}

create_dir()
{
  if [ ! -d "$1" ]
  then
    if [ ${VERBOSE} -ge 1 ]
    then
      echo "Создание директори:" "$1"
    fi
    ${MD} "$1"
  fi
}

sync_dirs()
{
  if [ ! -d "$1" ]
  then
    report_message "ERROR: Нет директории: $1"
    return 1
  fi
  
  if [ ! -d "$2" ]
  then
    report_message "ERROR: Нет директории: $2"
    return 1
  fi
  
  ${RSYNC} ${RSYNC_OPTS} --delete "$1" "$2"
}

sync_dirs_backup()
{
  if [ ! -d "$1" ]
  then
    report_message "ERROR: Нет директории: $1"
    return 1
  fi
  
  if [ ! -d "$2" ]
  then
    report_message "ERROR: Нет директории: $2"
    return 1
  fi
  
  if [ ! -d "$3" ]
  then
    report_message "ERROR: Нет директории: $3"
    return 1
  fi
  
  ${RSYNC} ${RSYNC_OPTS} --delete --backup --backup-dir="$3" --suffix="."$(eval ${TIMESTAMP}) "$1" "$2"
}

set_rsync_opts()
{
  if [ ${VERBOSE} -ge 2 ]
  then
    RSYNC_OPTS="--verbose"
  fi
  
  if [ ${VERBOSE} -ge 3 ]
  then
    RSYNC_OPTS="${RSYNC_OPTS} --verbose"
  fi
  
  if [ ${DRY_RUN} -eq 1 ]
  then
    RSYNC_OPTS="${RSYNC_OPTS} --dry-run --itemize-changes"
  fi
}

init_local_dirs()
{
  create_dir ${LOCAL_DOCS_DIR}
  create_dir ${LOCAL_PROJ_DIR}
  create_dir ${LOCAL_DOCS_BU_DIR}
  create_dir ${LOCAL_PROJ_BU_DIR}
}

init_remote_dirs()
{
  create_dir ${REMOTE_DOCS_DIR}
  create_dir ${REMOTE_PROJ_DIR}
}

sync_remote_to_local()
{
  if [ ${VERBOSE} -ge 1 ]
  then
    echo "Копирование данных в локальное хранилище:" ${LOCAL_DIR}
  fi
  
  confirm_choice
  RESULT=$?
  if [ ${RESULT} -ne 0 ]
  then
    report_message "WARN: Отмена!"
    return 1
  fi
  
  set_rsync_opts
  
  init_local_dirs
  
  sync_dirs_backup "${REMOTE_DOCS_DIR}/" "${LOCAL_DOCS_DIR}/" "${LOCAL_DOCS_BU_DIR}"
  sync_dirs_backup "${REMOTE_PROJ_DIR}/" "${LOCAL_PROJ_DIR}/" "${LOCAL_PROJ_BU_DIR}"
}

sync_local_to_remote()
{
  if [ ${VERBOSE} -ge 1 ]
  then
    echo "Копирование данных в удаленное хранилище:" ${REMOTE_DIR}
  fi
  
  confirm_choice
  RESULT=$?
  if [ ${RESULT} -ne 0 ]
  then
    report_message "WARN: Отмена!"
    return 1
  fi
  
  set_rsync_opts
  
  init_remote_dirs
  
  sync_dirs "${LOCAL_DOCS_DIR}/" "${REMOTE_DOCS_DIR}/"
  sync_dirs "${LOCAL_PROJ_DIR}/" "${REMOTE_PROJ_DIR}/"
}

show_help()
{
  printf "Cинхронизация хранилища $0\n"
  printf "Использование:\n"
  printf "\t$0 [-h]\n"
  printf "\t$0 -l [-n] [--local-dir <локальное хранилище>] [--remote-dir <удаленное хранилище>]\n"
  printf "\t$0 -s [-n] [--local-dir <локальное хранилище>] [--remote-dir <удаленное хранилище>]\n"
  printf "\t\t-s, --save - Сохранить данные из удаленного хранилища в локальное\n"
  printf "\t\t-l, --load - Загрузить данные из локального хранилища в удаленное\n"
  printf "\t\t-n, --dry-run - Показать изменения, которые будут произведены\n"
  printf "\t\t--yes - Соглашаться со всеми запросами\n"
  printf "\t\t--local-dir - Указать локальное хранилище\n"
  printf "\t\t--remote-dir - Указать удаленное хранилище\n"
  printf "\t\t-v, --verbose - Общительный режим\n"
}

print_debug()
{ 
  if [ ${VERBOSE} -lt 2 ]
  then
    return 1
  fi
  
  echo "Параметры" "$0"
  echo "Исполняемый файл:" "$EXECUTABLE"
  echo "Рабочая директория:" "$PWD"
  echo "Удаленная директория:" "$REMOTE_WORK_DIR"
  echo "Удаленная директория:" "$REMOTE_DOCS_DIR"
  echo "Удаленная директория:" "$REMOTE_PROJ_DIR"
  echo "Локальная директория:" "$LOCAL_WORK_DIR"
  echo "Локальная директория:" "$LOCAL_DOCS_DIR"
  echo "Локальная директория:" "$LOCAL_PROJ_DIR"
  echo "Локальная директория (для резерва):" "$LOCAL_DOCS_BU_DIR"
  echo "Локальная директория (для резерва):" "$LOCAL_PROJ_BU_DIR"
  echo "YES:" "$YES"
  echo "DRY_RUN:" "$DRY_RUN"
  echo "VERBOSE:" "$VERBOSE"
  echo "COMMAND:" "${COMMAND}"
}

parse_command()
{
  if [ $# -lt 1 ]
  then
    show_help
    exit 1
  fi
  
  COMMAND=""
  
  while :; do
    case $1 in
      -h|-\?|--help)
        show_help    # Display a usage synopsis.
        exit 0
        ;;
     -s|--save|--remote-to-local)         # Handle the case of an empty --file=
        if [ "${COMMAND}" == "" ]
        then
          COMMAND="remote-to-local"
        else
          report_message "ERROR: Разрешено только одно действие за раз!"
          return 1
        fi
        ;;
      -l|--load|--local-to-remote)       # Takes an option argument; ensure it has been specified.
        if [ "${COMMAND}" == "" ]
        then
          COMMAND="local-to-remote"
        else
          report_message "ERROR: Разрешено только одно действие за раз!"
          return 1
        fi
        ;;
      --local-dir)
        if [ "$2" ]; then
          LOCAL_DIR=$2
          LOCAL_WORK_DIR="${LOCAL_DIR}/work"
          LOCAL_DOCS_DIR="${LOCAL_WORK_DIR}/documents"
          LOCAL_PROJ_DIR="${LOCAL_WORK_DIR}/projects"
          LOCAL_DOCS_BU_DIR="${LOCAL_WORK_DIR}/documents_backup"
          LOCAL_PROJ_BU_DIR="${LOCAL_WORK_DIR}/projects_backup"
          shift
        else
          report_message "ERROR: \"--local-dir\" requires a non-empty option argument."
          return 1
        fi
        ;;
      --local-dir=?*)
        LOCAL_DIR=${1#*=} # Delete everything up to "=" and assign the remainder.
        LOCAL_WORK_DIR="${LOCAL_DIR}/work"
        LOCAL_DOCS_DIR="${LOCAL_WORK_DIR}/documents"
        LOCAL_PROJ_DIR="${LOCAL_WORK_DIR}/projects"
        LOCAL_DOCS_BU_DIR="${LOCAL_WORK_DIR}/documents_backup"
        LOCAL_PROJ_BU_DIR="${LOCAL_WORK_DIR}/projects_backup"
        ;;
      --local-dir=)         # Handle the case of an empty --file=
        report_message "ERROR: \"--local-dir\" requires a non-empty option argument."
        return 1
        ;;
      --remote-dir)
        if [ "$2" ]; then
          REMOTE_DIR=$2
          REMOTE_WORK_DIR="${REMOTE_DIR}/work"
          REMOTE_DOCS_DIR="${REMOTE_WORK_DIR}/documents"
          REMOTE_PROJ_DIR="${REMOTE_WORK_DIR}/projects"
          shift
        else
          report_message "ERROR: \"--remote-dir\" requires a non-empty option argument."
          return 1
        fi
        ;;
      --remote-dir=?*)
        REMOTE_DIR=${1#*=} # Delete everything up to "=" and assign the remainder.
        REMOTE_WORK_DIR="${REMOTE_DIR}/work"
        REMOTE_DOCS_DIR="${REMOTE_WORK_DIR}/documents"
        REMOTE_PROJ_DIR="${REMOTE_WORK_DIR}/projects"
        ;;
      --remote-dir=)         # Handle the case of an empty --file=
        report_message "ERROR: \"--remote-dir\" requires a non-empty option argument."
        return 1
        ;;
      -n|--dry-run)       # Takes an option argument;
        DRY_RUN=1
        ;;
      -y|--yes)       # Takes an option argument;
        YES=1
        ;;
      -v|--verbose)
        VERBOSE=$((VERBOSE + 1))  # Each -v adds 1 to verbosity.
        ;;
      --)              # End of all options.
        shift
        break
        ;;
      -?*)
        printf "WARN: Unknown option (ignored): %s\n" "$1" >&2
        ;;
      *)               # Default case: No more options, so break out of the loop.
        break
    esac

    shift
  done
}

execute_comand()
{
  case ${COMMAND} in
    remote-to-local)
      sync_remote_to_local
      return $?
      ;;
    local-to-remote)
      sync_local_to_remote
      return $?
      ;;
    *)
      report_message "ERROR: Не указана команда"
      return 1
  esac
}

parse_command "$@"
RESULT=$?
if [ ${RESULT} -ne 0 ]
then
  exit ${RESULT}
fi

print_debug

execute_comand

exit $?


