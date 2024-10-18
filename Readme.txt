Descripción del Bot de Trading en MQL5
Este bot de trading está diseñado para operar automáticamente en MetaTrader 5, implementando una estrategia basada en medias móviles. A continuación, se destacan los puntos más importantes del código que reflejan mis habilidades de programación:

1. Gestión de Riesgo Avanzada
El bot cuenta con una función que calcula el tamaño del lote de cada operación en base al balance de la cuenta y un porcentaje de riesgo fijo. Esto asegura que las operaciones se ajusten al tamaño de la cuenta, protegiendo el capital del usuario y minimizando riesgos excesivos.

mql
Copiar código
double get_lotage()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * PocentajeRiesgoPorOperacion;
    double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double lotage = riskAmount / (SL * pipValue);
    return NormalizeDouble(lotage, 2);
}
2. Integración de Indicadores Técnicos
El bot utiliza medias móviles simples de 30 y 100 periodos para identificar tendencias alcistas y bajistas mediante cruces de medias. Además, incluye una estructura lógica bien definida para asegurar que las condiciones de cruce se respeten antes de abrir una operación.

mql
Copiar código
mediaRapidaHandle = iMA(_Symbol, _Period, ma_30_period, 0, MODE_SMA, PRICE_CLOSE);
mediaLentaHandle = iMA(_Symbol, _Period, ma_100_period, 0, MODE_SMA, PRICE_CLOSE);
3. Control de Tiempo y Operaciones Diarias
El bot solo abre operaciones dentro de un horario específico, definido por las variables startHour y endHour. Además, cuenta con un límite de operaciones diarias (MAX_OPERACIONES_POR_DIA), asegurando un control sobre la cantidad de operaciones realizadas por día.

mql
Copiar código
if (currentHour >= startHour && currentHour <= endHour)
{
    // Lógica de operaciones
}
4. Gestión de Cierre Automático
El bot cierra todas las operaciones abiertas al final de la jornada, asegurando que no se queden posiciones abiertas fuera del horario permitido. Esto garantiza una gestión adecuada del riesgo y evita operaciones en horas de baja liquidez.

mql
Copiar código
if (StringSubstr(HorasMinutos, 0, 2) == Horafin)
{
    // Cerrar todas las posiciones abiertas
}
5. Notificaciones y Registro
El bot incluye mensajes informativos que se imprimen en el registro para monitorear el progreso y el estado de las operaciones. Estos mensajes facilitan el análisis posterior de las operaciones y permiten un mejor seguimiento de las decisiones del bot.

mql
Copiar código
Print("Operación de compra abierta con éxito. Ticket: ", trade_ticket);
Este bot no solo refleja mis conocimientos en el desarrollo de algoritmos de trading, sino también en la integración de gestión de riesgos, análisis técnico y control eficiente del flujo de operaciones. Todo esto, junto con la optimización del código para un rendimiento adecuado en tiempo real, demuestra mi habilidad para aplicar soluciones algorítmicas en entornos financieros automatizados.