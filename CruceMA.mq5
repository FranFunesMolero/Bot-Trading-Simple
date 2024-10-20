//+------------------------------------------------------------------+
//|                                                     Cruce-de-medias.mq5 |
//|                                                              Fran Funes |
//|                                                                  |
//+------------------------------------------------------------------+
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

// Inicializar el objeto de trading
CTrade trade;
ulong trade_ticket = 0;
bool time_passed = true;
datetime ultimaOperacion = 0;  // Hora de la última operación

// Parámetros constantes (no modificables por el usuario)
#define MAX_DIAS_USO 30   // Número máximo de días de uso permitido

// Parámetros de entrada
input double SL = 2000;                                  // Stop Loss en puntos
input double TP = 4000;                                  // Take Profit en puntos
input double startHour = 7.00;                          // Hora de inicio para abrir operaciones 
input double endHour = 17.00;                           // Hora de fin para abrir operaciones
input string Horafin = "20";                            // Hora de cierre de operaciones 
input int ma_30_period = 30;                            // Periodo de la media móvil rápida 
input int ma_100_period = 100;                          // Periodo de la media móvil lenta 
input double PocentajeRiesgoPorOperacion = 0.00001;       // % Riesgo por operacion en base al balance
input int IntervaloEntreOperaciones = (60 * 10);        // Intervalo en segundos de tiempo entre operaciones
input int MAX_OPERACIONES_POR_DIA = 10;                  // Máximo número de operaciones permitidas por día

// Variables adicionales
int operacionesDia = 0;                                 // Contador de operaciones por día
int ultimoDia = -1;                                     // Último día registrado
datetime fechaPrimeraOperacion = 0;                     // Fecha de la primera operación
bool primerUsoNotificado = false;

// Variables para notificaciones
bool cierreNotificado = false;
bool limiteNotificado = false;
bool fueraHorarioNotificado = false;
bool intervaloNotificado = false;  // Inicializar la variable para notificación de intervalo
double lastMediaRapidaValores[2] = {0.0, 0.0}; // Inicializar con valores predeterminados
double lastMediaLentaValores[2] = {0.0, 0.0};  // Inicializar con valores predeterminados

// Gestión de riesgo: cálculo del tamaño del lote basado en el balance de la cuenta
double get_lotage()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * PocentajeRiesgoPorOperacion; // Cantidad de riesgo en la moneda de la cuenta
    double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double lotage = riskAmount / (SL * pipValue); // Calcula el tamaño del lote
    lotage = NormalizeDouble(lotage, 2); // Normaliza el tamaño del lote
    return lotage;
}

// Indicadores
int mediaRapidaHandle = 0;
int mediaLentaHandle = 0;

// Arrays para almacenar los valores de los indicadores
double mediaRapidaValores[2];  // Inicializar tamaño del array
double mediaLentaValores[2];   // Inicializar tamaño del array

// Inicialización de los indicadores
int OnInit()
{
    mediaRapidaHandle = iMA(_Symbol, _Period, ma_30_period, 0, MODE_SMA, PRICE_CLOSE);
    mediaLentaHandle = iMA(_Symbol, _Period, ma_100_period, 0, MODE_SMA, PRICE_CLOSE);
    Print("Indicadores inicializados: Media Rápida con periodo ", ma_30_period, " y Media Lenta con periodo ", ma_100_period);
    return (INIT_SUCCEEDED);
}

// Evento que se ejecuta en cada tick
void OnTick()
{
    // Verificar si es la primera operación y almacenar la fecha
    if (fechaPrimeraOperacion == 0 && PositionsTotal() > 0)
    {
        fechaPrimeraOperacion = TimeCurrent();
        Print("Primera operación detectada. Fecha de inicio de uso: ", TimeToString(fechaPrimeraOperacion, TIME_DATE));
    }

    // Comprobar si la fecha actual supera el número máximo de días de uso permitido
    if (fechaPrimeraOperacion > 0)
    {
        datetime fechaActual = TimeCurrent();
        int diasUso = (int)((fechaActual - fechaPrimeraOperacion) / 86400); // Convertir segundos a días
        if (diasUso > MAX_DIAS_USO)
        {
            Print("El periodo de uso de ", MAX_DIAS_USO, " días ha expirado. El programa se detendrá.");
            ExpertRemove(); // Detener el script
            return;
        }
        else if (!primerUsoNotificado)
        {
            Print("Periodo de uso activo. Días restantes: ", MAX_DIAS_USO - diasUso);
            primerUsoNotificado = true;
        }
    }

    // Obtener la hora local actual
    datetime Time = TimeLocal();
    MqlDateTime timeStruct;
    TimeToStruct(Time, timeStruct);
    int currentHour = timeStruct.hour;
    int currentDay = timeStruct.day;
    string HorasMinutos = TimeToString(Time, TIME_MINUTES);

    // Cierre de operaciones a la hora especificada
    if (StringSubstr(HorasMinutos, 0, 2) == Horafin)
    {
        if (!cierreNotificado)
        {
            Print("Hora de cierre alcanzada: ", Horafin, ". Cerrando todas las posiciones.");
            cierreNotificado = true;
        }
        for (int b = 0; b < PositionsTotal(); b++)
        {
            ulong Ticket = PositionGetTicket(b);
            if (trade.PositionClose(Ticket))
                Print("Posición cerrada con éxito: Ticket ", Ticket);
            else
                Print("Error al cerrar posición: Ticket ", Ticket, " - Error: ", GetLastError());
        }
    }
    else
    {
        cierreNotificado = false;
    }

    // Solo operar dentro del horario permitido
    if (currentHour >= startHour && currentHour <= endHour)
    {
        if (currentDay != ultimoDia) {
            if (!fueraHorarioNotificado)
            {
                Print("Nuevo día detectado. Reiniciando contador de operaciones.");
                fueraHorarioNotificado = true;
            }
            operacionesDia = 0;
            ultimoDia = currentDay;
        }
        else
        {
            fueraHorarioNotificado = false;
        }

        // Verificar si se ha alcanzado el límite de operaciones diarias
        if (operacionesDia >= MAX_OPERACIONES_POR_DIA) {
            if (!limiteNotificado)
            {
                Print("Se ha alcanzado el límite diario de operaciones.");
                limiteNotificado = true;
            }
            return;
        }
        else
        {
            limiteNotificado = false;
        }

        // Copiar los valores de los indicadores
        if (CopyBuffer(mediaRapidaHandle, 0, 1, 2, mediaRapidaValores) > 0 &&
            CopyBuffer(mediaLentaHandle, 0, 1, 2, mediaLentaValores) > 0)
        {
            // Verificar si los valores de los indicadores han cambiado
            if (mediaRapidaValores[0] != lastMediaRapidaValores[0] || mediaRapidaValores[1] != lastMediaRapidaValores[1] ||
                mediaLentaValores[0] != lastMediaLentaValores[0] || mediaLentaValores[1] != lastMediaLentaValores[1])
            {
                // Imprimir valores solo cuando cambian
                lastMediaRapidaValores[0] = mediaRapidaValores[0];
                lastMediaRapidaValores[1] = mediaRapidaValores[1];
                lastMediaLentaValores[0] = mediaLentaValores[0];
                lastMediaLentaValores[1] = mediaLentaValores[1];
            }
        }

        // Verificar si no hay posiciones abiertas
        if (!PositionSelectByTicket(trade_ticket))
            trade_ticket = 0;

        // Verificar si ha pasado el intervalo de tiempo
        if (Time - ultimaOperacion >= IntervaloEntreOperaciones)
        {
            // Abrir operación de compra si se cumplen las condiciones
            if (mediaRapidaValores[1] > mediaLentaValores[1] && mediaRapidaValores[0] < mediaLentaValores[0] && trade_ticket <= 0 && time_passed == true)
            {
                double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
                double lotage = get_lotage();

                if (trade.Buy(lotage, _Symbol, Ask, Ask - SL * _Point, Ask + TP * _Point, NULL))
                {
                    trade_ticket = trade.ResultOrder();
                    ultimaOperacion = Time;  // Actualizar la hora de la última operación
                    operacionesDia++;        // Incrementar el contador de operaciones diarias
                    time_passed = false;
                    EventSetTimer(IntervaloEntreOperaciones); // Establecer un temporizador para permitir abrir otra operación
                    Print("Operación de compra abierta con éxito. Ticket: ", trade_ticket, ", Lote: ", lotage, ", SL: ", Ask - SL * _Point, ", TP: ", Ask + TP * _Point);
                }
                else
                {
                    Print("Error al abrir operación de compra. Error: ", GetLastError());
                }
            }
            
            // Abrir operación de venta si se cumplen las condiciones
            if (mediaRapidaValores[1] < mediaLentaValores[1] && mediaRapidaValores[0] > mediaLentaValores[0] && trade_ticket <= 0 && time_passed == true)
            {
                double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
                double lotage = get_lotage();

                if (trade.Sell(lotage, _Symbol, Bid, Bid + SL * _Point, Bid - TP * _Point, NULL))
                {
                    trade_ticket = trade.ResultOrder();
                    ultimaOperacion = Time;  // Actualizar la hora de la última operación
                    operacionesDia++;        // Incrementar el contador de operaciones diarias
                    time_passed = false;
                    EventSetTimer(IntervaloEntreOperaciones); // Establecer un temporizador para permitir abrir otra operación
                    Print("Operación de venta abierta con éxito. Ticket: ", trade_ticket, ", Lote: ", lotage, ", SL: ", Bid + SL * _Point, ", TP: ", Bid - TP * _Point);
                }
                else
                {
                    Print("Error al abrir operación de venta. Error: ", GetLastError());
                }
            }
        }
        else
        {
            if (!intervaloNotificado)
            {
                Print("No ha pasado el intervalo requerido entre operaciones.");
                intervaloNotificado = true;
            }
        }
    }
    else
    {
        if (!fueraHorarioNotificado)
        {
            Print("Hora actual fuera del rango permitido para abrir operaciones: ", currentHour);
            fueraHorarioNotificado = true;
        }
    }
}

// Evento que se ejecuta cuando el temporizador expira
void OnTimer()
{
    time_passed = true;
    intervaloNotificado = false; // Reiniciar la notificación del intervalo
}
