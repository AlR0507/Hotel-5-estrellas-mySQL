import tkinter as tk
from tkinter import messagebox, ttk
import mysql.connector

# ----------------- Styles and Theme -----------------
style = ttk.Style()
style.theme_use('clam')  # Modern theme

# Configure Treeview styles
style.configure('Treeview',
                font=('Helvetica', 10),
                rowheight=24,
                background='white',
                fieldbackground='white')
style.configure('Treeview.Heading',
                font=('Helvetica', 11, 'bold'))
style.map('Treeview',
          background=[('selected', '#4CAF50')],
          foreground=[('selected', 'white')])

# Configure general widget styles
style.configure('TButton', font=('Helvetica', 10), padding=6)
style.configure('TLabelframe', font=('Helvetica', 12, 'bold'), background='#f5f5f5')
style.configure('TLabelframe.Label', font=('Helvetica', 13, 'bold'))

# ----------------- Database Connection -----------------
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="u7pjjiicEARM2005",
        database="bdproyecto"
    )

# ----------------- CRUD Functions -----------------
def insertar_huesped():
    campos_obligatorios = [
        entry_nombre.get(), entry_apellido.get(), entry_fechaNacimiento.get(),
        entry_sexo.get(), entry_telefonoCelular.get(), entry_lugarProcedencia.get()
    ]
    if any(not v.strip() for v in campos_obligatorios):
        messagebox.showerror("Error", "Los campos marcados con * son obligatorios.")
        return

    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO huesped "
            "(nombre, apellido, fechaNacimiento, sexo, telefonoCasa, telefonoCelular, email, rfc, lugarProcedencia) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (
                entry_nombre.get(), entry_apellido.get(), entry_fechaNacimiento.get(),
                entry_sexo.get(), entry_telefonoCasa.get(), entry_telefonoCelular.get(),
                entry_email.get(), entry_rfc.get(), entry_lugarProcedencia.get()
            )
        )
        conn.commit()
        cursor.close()
        conn.close()

        messagebox.showinfo("Éxito", "Huésped agregado correctamente.")
        for e in entries:
            e.delete(0, tk.END)
    except mysql.connector.Error as err:
        messagebox.showerror("Error en BD", f"{err}")

# ----------------- Display Table -----------------
def mostrar_tabla(nombre_tabla):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM {nombre_tabla}")
        filas = cursor.fetchall()
        columnas = [desc[0] for desc in cursor.description]

        win = tk.Toplevel(ventana)
        win.title(f"{nombre_tabla.capitalize()}")
        win.geometry("900x450")
        win.configure(bg='#f5f5f5')

        frame = ttk.Frame(win)
        frame.pack(fill='both', expand=True, padx=10, pady=10)

        tree = ttk.Treeview(frame, columns=columnas, show='headings')
        vsb = ttk.Scrollbar(frame, orient='vertical', command=tree.yview)
        hsb = ttk.Scrollbar(frame, orient='horizontal', command=tree.xview)
        tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        tree.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')
        hsb.grid(row=1, column=0, sticky='ew')
        frame.grid_rowconfigure(0, weight=1)
        frame.grid_columnconfigure(0, weight=1)

        # Configure columns
        for col in columnas:
            tree.heading(col, text=col)
            tree.column(col, width=120, anchor='center')

        # Insert rows with striped effect
        for idx, fila in enumerate(filas):
            tag = 'evenrow' if idx % 2 == 0 else 'oddrow'
            tree.insert('', 'end', values=fila, tags=(tag,))
        tree.tag_configure('evenrow', background='white')
        tree.tag_configure('oddrow', background='#e8f4f8')

        cursor.close()
        conn.close()
    except mysql.connector.Error as err:
        messagebox.showerror("Error en BD", f"{err}")

# ----------------- Main Interface -----------------
ventana = tk.Tk()
ventana.title("Gestión de Base de Datos")
ventana.geometry("650x750")
ventana.configure(bg='#f5f5f5')
ventana.resizable(False, False)

# Form Frame
form_frame = ttk.Labelframe(ventana, text="Agregar Huésped")
form_frame.pack(fill='x', padx=20, pady=15)

labels = [
    "Nombre*", "Apellido*", "Fecha Nacimiento* (YYYY-MM-DD)", "Sexo* (M/F)",
    "Teléfono Casa", "Teléfono Celular*", "Email", "RFC", "Lugar Procedencia*"
]
entries = []
for i, txt in enumerate(labels):
    lbl = ttk.Label(form_frame, text=txt)
    lbl.grid(row=i, column=0, sticky='w', padx=5, pady=4)
    ent = ttk.Entry(form_frame, width=40)
    ent.grid(row=i, column=1, padx=5, pady=4)
    entries.append(ent)

entry_nombre, entry_apellido, entry_fechaNacimiento, entry_sexo, \
entry_telefonoCasa, entry_telefonoCelular, entry_email, entry_rfc, entry_lugarProcedencia = entries

btn_agregar = ttk.Button(
    form_frame, text="Agregar Huésped", command=insertar_huesped, style='TButton'
)
btn_agregar.grid(row=len(labels), column=0, columnspan=2, pady=12)

# Tables Frame
btn_frame = ttk.Labelframe(ventana, text="Mostrar Tablas")
btn_frame.pack(fill='both', padx=20, pady=10)

tablas = ["huesped", "habitacion", "reserva", "factura", "empleado", "cliente_vip"]
for i, tabla in enumerate(tablas):
    btn = ttk.Button(
        btn_frame, text=tabla.capitalize(),
        command=lambda t=tabla: mostrar_tabla(t)
    )
    btn.grid(row=i//2, column=i%2, padx=10, pady=8, sticky='ew')
    btn_frame.grid_columnconfigure(i%2, weight=1)

ventana.mainloop()
